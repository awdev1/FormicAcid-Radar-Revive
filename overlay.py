
import math
from tkinter import Canvas, Tk, Toplevel

import requests

realcodes = {
    "IRFD": "LFML",
    "IMLR": "EGGD",
    "IPPH": "YPPH",
    "IGRV": "BIKF",
    "ITKO": "RJTT"
}


roundAngle = True
airportCode = None

start_x = None
start_y = None
line = None
line_2 = None
angle_label = None
angle_label_bg = None
hasMoved = False
label_metar = None
label_metar_bg = None
sceneList = []
sceneListData = []
cl_rq = None
cl_ev = None



transparent_color = 'grey15'

root = Tk()
root.attributes('-alpha', 0.002)
root.attributes('-topmost', True)
root.geometry("1920x1080+1920+0")
root.overrideredirect(True)

top = Toplevel(root)
top.attributes('-transparentcolor', transparent_color)
top.attributes('-topmost', True)
top.geometry("1920x1080+1920+0")
top.overrideredirect(True)
root.focus_set()
canvas = Canvas(top, bg=transparent_color, highlightthickness=0)
canvas.pack(fill='both', expand=True)


def on_click(event):    
    global start_x, start_y, sceneList
    start_x = event.x
    start_y = event.y
    for i in sceneListData:
        bbox = i["bbox"]
        if (bbox[0] < start_x and bbox[2] > start_x and bbox[1] < start_y and bbox[3] > start_y):
            cl_rq.send("SetCurrentProgramScene", data={
                "sceneName": i["scene"]
            })
            start_x = None
            start_y = None
            drawScenes()
            break

def on_drag(event):
    global start_x, start_y, hasMoved

    if start_x is not None and start_y is not None:
        hasMoved = True
        current_x = event.x
        current_y = event.y
        draw_line(start_x, start_y, current_x, current_y)
        show_angle(start_x, start_y, current_x, current_y)

def on_move(event):
    global sceneList, sceneListData, currScene
    root.config(cursor="crosshair")
    for i in sceneListData:
        bbox = i["bbox"]
        if (currScene == i["scene"]):
            continue
        if (bbox[0] < event.x and bbox[2] > event.x and bbox[1] < event.y and bbox[3] > event.y):
            root.config(cursor="dotbox")
            canvas.itemconfig(i["id"], fill="#333333")
        else:
            canvas.itemconfig(i["id"], fill="#2d2d2d")

def on_release(event):
    global start_x, start_y, hasMoved, canvas, angle_label, angle_label_bg, line, line_2
    if not hasMoved:
        if angle_label:
            canvas.delete(angle_label)
        if angle_label_bg:
            canvas.delete(angle_label_bg)
        if line:
            canvas.delete(line)
            canvas.delete(line_2)
    hasMoved = False
    start_x = None
    start_y = None

def draw_line(start_x, start_y, end_x, end_y):
    global line, canvas, line_2
    if line:
        canvas.delete(line)
        canvas.delete(line_2)
    line_2 = canvas.create_line(start_x, start_y, end_x, end_y, fill='#666666', width=3.5)
    line = canvas.create_line(start_x, start_y, end_x, end_y, fill='#b2b2b2', width=3)

def show_angle(start_x, start_y, end_x, end_y):
    global angle_label, canvas, angle_label_bg
    angle = math.degrees(math.atan2(end_y - start_y, end_x - start_x)) + 90
    if angle <= 0:
        angle += 360
    if (roundAngle):
        angle = (round(angle / 5)) * 5
    if angle_label:
        canvas.delete(angle_label)
    if angle_label_bg:
        canvas.delete(angle_label_bg)
    if roundAngle:
        angle_label = canvas.create_text(end_x, end_y, text=f'{angle:.0f}°', fill='#b2b2b2', font="Arial 12")
    else:
        angle_label = canvas.create_text(end_x, end_y, text=f'{angle:.2f}°', fill='#b2b2b2', font="Arial 12")
    angle_label_bg = canvas.create_rectangle(canvas.bbox(angle_label),fill="#242628", outline="grey15")
    canvas.tag_lower(angle_label_bg, angle_label)

def update_metar():
    global airportCode, label_metar, label_metar_bg
    if label_metar:
        canvas.delete(label_metar)
        canvas.delete(label_metar_bg)
    if airportCode == None:
        root.after(5000, update_metar)
        return
    label_metar = canvas.create_text(10, 25, text='', fill='#b2b2b2', font="Arial 12", anchor="w")
    url = f"https://aviationweather.gov/api/data/metar?ids={airportCode}"
    try:
        response = requests.get(url)
        metar = response.text.replace("\n", "")
        canvas.itemconfig(label_metar, text=metar)
        label_metar_bg = canvas.create_rectangle(canvas.bbox(label_metar), fill='#242628', outline=transparent_color)
        canvas.tag_lower(label_metar_bg, label_metar)
    except Exception as e:
        print("Error fetching METAR:", e)

    root.after(20000, update_metar)

def fetch_from_backend():
    r = requests.get("http://localhost:5173")
    print(r.json())
    root.after(500, fetch_from_backend)
# fetch_from_backend()
    
import obsws_python as obs

cl_rq = obs.ReqClient(host='localhost', port=4455, password='', timeout=3)
cl_ev = obs.EventClient(host='localhost', port=4455, password='', timeout=3)



def on_current_scene_collection_changed(ev):
    global airportCode, realcodes
    airport = ev.scene_collection_name
    if (airport in realcodes.keys()):
        airportCode = realcodes[airport]
    else:
        airportCode = airport
    update_metar()
    drawScenes()

cl_ev.callback.register(on_current_scene_collection_changed)

resp = cl_rq.send("GetSceneCollectionList", raw=True)
airport = resp["currentSceneCollectionName"]
if (airport in realcodes.keys()):
    airportCode = realcodes[airport]
else:
    airportCode = airport

currScene = None
def drawScenes():
    global sceneList, currScene, sceneListData
    for i in sceneList:
        canvas.delete(i)
    sceneList = []
    sceneListData = []
    resp = cl_rq.send("GetSceneList", raw=True)
    scenes = resp["scenes"]
    currScene = resp["currentProgramSceneName"]
    scenes.reverse()
    scenes = list(map(lambda e: e["sceneName"], scenes))
    for i, scene in enumerate(scenes):
        a = canvas.create_text(1835, 5 + i * (35) , anchor="n", text=scene, fill='#b2b2b2', font="Arial 12")
        bbox = canvas.bbox(a)
        bbox = (1750, bbox[1] - 8, 1920, bbox[3] + 8)
        if (scene == currScene):
            b = canvas.create_rectangle(bbox,fill="#414141", outline="#414141")
        else:
            b = canvas.create_rectangle(bbox,fill="#2d2d2d", outline="#2d2d2d")
        canvas.tag_lower(b, a)
        sceneList.append(a)
        sceneList.append(b)
        sceneListData.append({
            "bbox": canvas.bbox(b),
            "scene": scene,
            "id": b
        })

def set_scene(event):
    print(event)


update_metar()
drawScenes()

root.bind('<Button-1>', on_click)
root.bind('<B1-Motion>', on_drag)
root.bind('<Motion>', on_move)
root.bind('<ButtonRelease-1>', on_release)
root.mainloop()
