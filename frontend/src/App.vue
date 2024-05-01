<template>
    <div id="map_canvas" v-if="display">

    </div>
    <div class="ctrl" v-else-if="obs_open">
        <div class="cats" >
            <div v-for="cat in sceneCategories" class="cat">
                <div v-if="ap.topDowns?.includes(cat) || ap.code == cat">
                    <p class="cat_name">{{ cat }}</p>
                    <div class="cat_body">
                        <div v-for="i in scenes" :class="currentScene == i.name ? 'scene active' : 'scene'" @click="select(i.name)">
                            <p v-if="i.name.split('_')[0].trim() == cat && (i.airport == ap.code || i.airport == undefined)">{{ i.name }}</p>
                        </div>
                    </div>
                </div>
            </div>
    
        </div>
        <div class="settings">
            <p>Runways</p>
            <div class="rws" v-for="rw, i in ap.runwayInfo">
                <div class="rw" @click="updateRunway(ap.code + rw.name1)" :class="`rw-` + ap.runwayInfo.length * 2">
                    <input type="checkbox" :checked="settings.runways.includes(ap.code + rw.name1)" readonly>
                    <p>{{ rw.name1 }}</p>
                </div>
                <div class="rw" @click="updateRunway(ap.code + rw.name2)" :class="`rw-` + ap.runwayInfo.length * 2">
                    <input type="checkbox" :checked="settings.runways.includes(ap.code + rw.name2)" readonly>
                    <p>{{ rw.name2 }}</p>
                </div>
            </div>
            <div class="td" v-for="td in getTDs()">
                <p class="small">{{ td.code }}</p>
                <div class="rws" v-for="rw, i in td.runwayInfo">
                    <div class="rw" @click="updateRunway(td.code + rw.name1)" :class="`rw-` + td.runwayInfo.length * 2">
                        <input type="checkbox" :checked="settings.runways.includes(td.code + rw.name1)" readonly>
                        <p>{{ rw.name1 }}</p>
                    </div>
                    <div class="rw" @click="updateRunway(td.code + rw.name2)" :class="`rw-` + td.runwayInfo.length * 2">
                        <input type="checkbox" :checked="settings.runways.includes(td.code + rw.name2)" readonly>
                        <p>{{ rw.name2 }}</p>
                    </div>
                </div>
            </div>
            <p>Settings</p>
            <div class="rw" @click="settings.terrain = !settings.terrain; setSettings()">
                <input type="checkbox" :checked="settings.terrain" readonly>
                <p>Show Terrain</p>
            </div>
        </div>
    </div>
    <div v-else class="noconn">
        <p>
                       Could not connect to OBS. 
                       Check your OBS Websocket Settings 
                       or install node and Python from the redist folder
        </p>
    </div>
</template>

<script setup lang="ts">
import L, { Map, Popup, point, type LatLngBoundsExpression, type LatLngExpression } from "leaflet";
import "leaflet/dist/leaflet.css";
import OBSWebSocket from "obs-websocket-js";
import { findAirport, generateVORDMEs, generateVORTACs, generateWaypoints, type Airport, type Fix } from "ptfst-db";
import { onBeforeUnmount, onMounted, reactive, ref, watch, type Ref } from "vue";
import { configs, type Config } from "./Configs";

let display = ref(true)
let scenes: Ref<Config[]> = ref([])
let currentScene: Ref<string> = ref("")
let sceneCategories: Ref<string[]> = ref([])
let obs: OBSWebSocket;
let map: Map;

let obs_open = ref(false)

function getTDs(): Airport[] {
    if (ap.value.topDowns == undefined) return [] as Airport[]

    return ap.value.topDowns.map(e => findAirport(e))
}

let settings = reactive({
    airport: "",
    runways: [] as string[],
    terrain: true,
    roundHeadings: true
})

function updateRunway(name: string) {
    if (settings.runways.includes(name)) {
        settings.runways = settings.runways.filter(e => e != name)
    } else {
        settings.runways.push(name)
    }
    setSettings()
}

let ap_c = "IRFD";
let ap: Ref<Airport> = ref(findAirport(ap_c));

let iv = -1


onMounted(() => {
    obs = new OBSWebSocket();
    let params = new URLSearchParams(window.location.search)
    display.value = params.get("display") != null
    obs.connect("ws://localhost:4455").then(() => {
        obs_open.value = true
        obs.on("ConnectionClosed", (data) => {
            obs_open.value = false
        })
        obs.call("GetSceneCollectionList").then(s => {
            ap.value = findAirport(s.currentSceneCollectionName);
            obs.on("CurrentSceneCollectionChanged", (data) => {
                ap.value = findAirport(data.sceneCollectionName);
            })
        })
        obs.call("GetSceneList").then(s => {
            s.scenes.reverse()
            scenes.value = []
            sceneCategories.value = []
            s.scenes.map(e => e.sceneName as string).forEach(e => {
                let search = configs.find(c => c.name == e)
                if (search == undefined) return
                scenes.value.push(search)
                let cat = e.split("_")[0].trim()
                if (!sceneCategories.value.includes(cat)) {
                    sceneCategories.value.push(cat)
                }
            })
            currentScene.value = s.currentProgramSceneName
            if (display.value) {
                dsply()
            }
            let config = configs.find(e => e.name == currentScene.value) as Config
            watch(currentScene, () => {
                config = configs.find(e => e.name == currentScene.value) as Config
                if (config == undefined || map == undefined) return
                dsply()
            })
            obs.on("CurrentProgramSceneChanged", (data) => {
                currentScene.value = data.sceneName
            })
        })
    })
    iv = setInterval(getSettings, 500)
    getSettings()
})
onBeforeUnmount(() => {
    clearInterval(iv)
})

let mapOffset = {
    x: -47,
    y: 2773 + 3.5
}

function process(f: Fix[]) {
    f.forEach(e => {
        e.x = (e.x / 3709) * 256 * 1.37 + mapOffset.x
        e.y = (e.y / 2773) * 256 * 1.025 + mapOffset.y
    })
    return f
}
let waypoints = process(generateWaypoints())
let vordmes = process(generateVORDMEs())
let vortacs = process(generateVORTACs())
let runways = [
    {
        length: 6.4,
        heading: 360,
        x: 98.385,
        y: -180.58,
        name1: "IRFD36L",
        name2: "IRFD18R",
    },
    {
        length: 4.4,
        heading: 0,
        x: 99.13,
        y: -179.62,
        name1: "IRFD36R",
        name2: "IRFD18L"
    },
    {
        length: 4.3,
        heading: 110,
        x: 108.08,
        y: -180.95,
        name1: "IMLR11",
        name2: "IMLR29"
    },
    {
        length: 2.8,
        heading: 7.4,
        x: 92.74,
        y: -169.5,
        name1: "IGAR01",
        name2: "IGAR19"
    },
    {
        length: 0.7,
        heading: 153.5,
        x: 100.95,
        y: -168.95,
        name1: "IBLT15",
        name2: "IBLT33"
    },
    {
        length: 1.5,
        heading: 180,
        x: 111.1,
        y: -200.5,
        name1: "ITRC18",
        name2: "ITRC36"
    },
    {
        length: 6.35,
        heading: 111,
        x: 179.1,
        y: -73.1,
        name1: "IPPH11",
        name2: "IPPH29"
    },
    {
        length: 5,
        heading: 151,
        x: 178.1,
        y: -72.3,
        name1: "IPPH15",
        name2: "IPPH33"
    },
    {
        length: 1.5,
        heading: 89,
        x: 190.7,
        y: -83.8,
        name1: "ILKL09",
        name2: "ILKL27"
    },
    {
        length: 3.4,
        heading: 62,
        x: 16,
        y: -120.05,
        name1: "IGRV06",
        name2: "IGRV24"
    },
    {
        length: 1,
        heading: 40,
        x: 19,
        y: -126.05,
        name1: "TVO04W",
        name2: "TVO22W"
    },
    {
        length: 5.5,
        heading: 20,
        x: 113.1,
        y: -43.6,
        name1: "ITKO02",
        name2: "ITKO20"
    },
    {
        length: 6.9,
        heading: 127.8,
        x: 108.3,
        y: -40.1,
        name1: "ITKO13",
        name2: "ITKO31"
    },
    {
        length: 1.2,
        heading: 73,
        x: 117.7,
        y: -8.2,
        name1: "IDCS07",
        name2: "IDCS25"
    },
]
let apts = [
    {
        x: 92.74,
        y: -169.5,
        name: "IGAR"
    },
    {
        x: 99.385,
        y: -180.58,
        name: "IRFD"
    },
    {
        x: 101.1,
        y: -169.1,
        name: "IBLT"
    },
    {
        x: 108.08,
        y: -179.95,
        name: "IMLR"
    },
    {
        x: 110.8,
        y: -200.5,
        name: "ITRC"
    },
]
let popups: Popup[] = []
function dsply() {
    popups.forEach(e => {
        e.remove()
    })
    popups = []
    let config = configs.find(e => e.name == currentScene.value) as Config
    if (map != undefined) {
        map.remove()
    }
    map = L.map('map_canvas', {
        crs: L.CRS.Simple,
        minZoom: 1,
        maxZoom: 8,
    })

    if (config.fixes) {
        waypoints.forEach(waypoint => {
            let polygon = L.polygon([
                [2773 - waypoint.y - .5, waypoint.x - 1.0],
                [2773 - waypoint.y - .5, waypoint.x + 1.0],
                [2773 - waypoint.y + 1.5, waypoint.x],
            ], {
                color: "#ffffff",
                smoothFactor: 0,
                weight: 1,
            }).addTo(map)
            let pop = L.popup({
                content: waypoint.name,
                offset: point(40, 45)
            }).setLatLng([2773 - waypoint.y, waypoint.x])
            .addTo(map)
            popups.push(pop)

            
        })
        vordmes.forEach(waypoint => {
            let polygon = L.polygon([
                [
                    [2773 - waypoint.y - .75, waypoint.x - 1.0],
                    [2773 - waypoint.y - .75, waypoint.x + 1.0],
                    [2773 - waypoint.y + .75, waypoint.x + 1.0],
                    [2773 - waypoint.y + .75, waypoint.x - 1.0],
                ],
                [
                    [2773 - waypoint.y, waypoint.x - .8],
                    [2773 - waypoint.y + .65, waypoint.x - .4],
                    [2773 - waypoint.y + .65, waypoint.x + .4],
                    [2773 - waypoint.y, waypoint.x + .8],
                    [2773 - waypoint.y - .65, waypoint.x + .4],
                    [2773 - waypoint.y - .65, waypoint.x - .4],
                ]
            ], {
                color: "#ffffff",
                smoothFactor: 0,
                weight: 1,
            }).addTo(map);
            let pop = L.popup({
                content: waypoint.name,
                offset: point(40, 45)
            }).setLatLng([2773 - waypoint.y, waypoint.x])
            .addTo(map)
            popups.push(pop)
        })
        vortacs.forEach(waypoint => {
            let coordinates: LatLngExpression[][] = [
                [
                    [2773 - waypoint.y - 1.5, waypoint.x - .45],
                    [2773 - waypoint.y - 1.5, waypoint.x + .45],
                    [2773 - waypoint.y - .9, waypoint.x + .45],
                    [2773 - waypoint.y - .9, waypoint.x - .45],
                ],
                [
                    [2773 - waypoint.y - .9, waypoint.x - .45],
                    [2773 - waypoint.y + .4, waypoint.x - 1.2],
                ],
                [
                    [2773 - waypoint.y + .7, waypoint.x + 1.7],
                    [2773 - waypoint.y + 1.4, waypoint.x + 1.25],
                    [2773 - waypoint.y + 1.15, waypoint.x + .75],
                    [2773 - waypoint.y + .4, waypoint.x + 1.2],
                    [2773 - waypoint.y + .7, waypoint.x + 1.7],
                ],
                [
                    [2773 - waypoint.y + .4, waypoint.x + 1.2],
                    [2773 - waypoint.y - .9, waypoint.x + .45],
                ],
                [
                    [2773 - waypoint.y + 1.15, waypoint.x + .75],
                    [2773 - waypoint.y + 1.15, waypoint.x - .75],
                ],
                [
                    [2773 - waypoint.y + .7, waypoint.x - 1.7],
                    [2773 - waypoint.y + 1.4, waypoint.x - 1.25],
                    [2773 - waypoint.y + 1.15, waypoint.x - .75],
                    [2773 - waypoint.y + .4, waypoint.x - 1.2],
                    [2773 - waypoint.y + .7, waypoint.x - 1.7],
                ],
    
            ]
    
            let polygon = L.polygon(coordinates, {
                color: "#ffffff",
                smoothFactor: 0,
                weight: 1,
            }).addTo(map);
            let pop = L.popup({
                content: waypoint.name,
                offset: point(40, 45)
            }).setLatLng([2773 - waypoint.y, waypoint.x])
            .addTo(map)
            popups.push(pop)
        })
    }

    
    
    let bounds: LatLngBoundsExpression = [[0, 0], [1, 1]];
    if (settings.terrain) {
        L.tileLayer('/tiles/{z}/tile_{x}_{y}.png', {
            maxZoom: 8,
            maxNativeZoom: 6,
            minNativeZoom: 0,
            minZoom: 1,
        }).addTo(map)
    }
    
    L.imageOverlay("/airspaces.svg", [[-504, -47], [235, 304]]).addTo(map)


    runways.forEach(runway => {
        if (!config.locs) return
        let h = runway.heading
        let l = runway.length
        let x = runway.x
        let y = runway.y
        let a = Math.sin(h * (Math.PI/180))
        let b = Math.cos(h * (Math.PI/180))
        let l2 = 8.5
        let s = -14.5
        let startthresh = s + l2 * 3
        L.polyline(
            [
                [y - l * b / 2, x - l * a / 2],
                [y + l * b / 2, x + l * a / 2],
            ],
            {
                color: "#ffffff"
            }
        ).addTo(map)

        // Approach Markings
        for (let i = 0; i < 5; i++) {
            if (!settings.runways.includes(runway.name1)) break
            L.polyline(
                [
                    [y - ((l - s * i + (l2 / 2) + startthresh) * b) / 2, x - ((l - s * i + l2 / 2 + startthresh) * a) / 2],
                    [y - ((l - s * i - (l2 / 2) + startthresh) * b) / 2, x - ((l - s * i - l2 / 2 + startthresh) * a) / 2],
                ],
                {
                    color: "#ffffff"
                }
            ).addTo(map)
        }
        for (let i = 0; i < 5; i++) {
            if (!settings.runways.includes(runway.name2)) break
            L.polyline(
                [
                    [y + ((l - s * i + (l2 / 2) + startthresh) * b) / 2, x + ((l - s * i + l2 / 2 + startthresh) * a) / 2],
                    [y + ((l - s * i - (l2 / 2) + startthresh) * b) / 2, x + ((l - s * i - l2 / 2 + startthresh) * a) / 2],
                ],
                {
                    color: "#ffffff"
                }
            ).addTo(map)
        }
    })

    if (config.ctr) {
        L.imageOverlay("/irfd ctr.svg", [[-232, 85.85], [-135, 118.15]]).addTo(map)
        L.imageOverlay("/itko ctr.svg", [[-62, 223], [-1, 0]]).addTo(map)
    }
    apts.forEach(airport => {
        if (!config.airportNames) return
        let pop = L.popup({
            content: airport.name,
            offset: point(40, 45)
        }).setLatLng([airport.y, airport.x])
        .addTo(map)
        popups.push(pop)
    })



    map.fitBounds(bounds).setView([config.y, config.x], config.zoom, {
        animate: false
    });
}

function select(s: string) {
    currentScene.value = s
    obs.call("SetCurrentProgramScene", {sceneName: currentScene.value})
}

async function getSettings() {
    let s = await fetch("http://localhost:6969/settings")
    let json = await s.json()
    let changed = false
    if (!arrayEquals(JSON.parse(JSON.stringify(settings.runways)), json.runways)) {
        settings.runways = json.runways
        changed = true
    }
    if (settings.terrain != json.terrain) {
        settings.terrain = json.terrain
        changed = true
    }
    if (changed && map != undefined) {
        dsply()
    }
}
async function setSettings() {
    fetch("http://localhost:6969/settings", {
        method: "POST",
        body: JSON.stringify(settings),
        headers: {
            "Content-Type": "application/json"
        }
    })
}

function arrayEquals(a: any[], b: any[]) {
    return Array.isArray(a) &&
        Array.isArray(b) &&
        a.length === b.length &&
        a.every((val, index) => val === b[index]);
}
</script>

<style scoped>
#map_canvas {
    width: 100vw;
    height: 100vh;
    background-color: #3b5a7e;
    filter: contrast(1.8) brightness(0.7) grayscale(0.95) ;
}
.cat {
    height: 100vh;
    width: 10vw;
}
.cat_name {
    text-align: center;
    padding: 1vh 1vw 1vh 1vw;
    font-size: 1.25em;
    height: 5vh;
}
.cats {
    background-color: #202020;
    height: 100vh;
    width: 70vw;
    display: flex;
}
.cat_body {
    height: 95vh;
    width: 100%;
}
.scene {
    text-align: center;
    background-color: #2d2d2d;
}
.scene:hover {
    background-color: #333333;
}
.scene p {
    padding: 0.5vh 0.5vw 0.5vh 0.5vw;
    font-size: 0.75em;
    cursor: pointer;
}
.active {
    background-color: #414141 !important;
}
.settings {
    width: 30vw;
    height: 100vh;
    background-color: rgb(28, 28, 28);
}
.ctrl {
    width: 100vw;
    height: 100vh;
    display: flex;
}
.settings p {
    font-size: 2.5em;
    text-align: center;
}
.settings select {
    width: 100%;
    height: 5vh;
    background-color: #212121;
    border: none;
    outline: none;
    color: white;
    padding: 1vh 1vw 1vh 1vw;    
}
.rws {
    width: 100%;
    display: flex;
}
.rw {
    display: flex;
    align-items: center;
    padding-left: 1vw;
    font-size: 1vh;
    width: calc(100% - 1vw);
    cursor: pointer;
    background-color: #1c1c1c;
}
.rw:hover {
    background-color: #2d2d2d;
}
.small {
    font-size: 1em !important;
}
.td {
    background-color: #272727;
    width: calc(100% - 3vw);
    padding: 0.5vh 1vw 2.5vh 1vw;
    margin-top: 1vh;
    margin-left: 0.5vw;
    border-radius: 0.25em;
}
.td p.small {
    margin-bottom: 0.5vh;
}
.td .rw {
    background-color: #272727;
    padding-left: 0;
}
.td .rw:hover {
    
    background-color: #333333;
}
.rw-2 {
    width: 50%;
}
.rw-4 {
    width: 50%;
}
.noconn {
    width: 100vw;
    height: 100vh;
    background-color: #202020;
    display: flex;
    align-items: center;
    justify-content: center;
}
.noconn p {
    font-size: 5vh;
}
.cat:empty {
    display: none;
}
</style>
