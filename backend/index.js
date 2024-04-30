"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const body_parser_1 = __importDefault(require("body-parser"));
const cors_1 = __importDefault(require("cors"));
const express_1 = __importDefault(require("express"));
let app = (0, express_1.default)();
app.use((0, cors_1.default)());
app.use(body_parser_1.default.urlencoded({ extended: true }));
app.use(body_parser_1.default.json());
app.use(body_parser_1.default.raw());
let settings = {
    airport: "",
    runways: [],
    terrain: true,
    roundHeadings: true
};
app.post("/settings", (req, res) => {
    Object.keys(req.body).forEach(key => {
        settings[key] = req.body[key];
    });
    res.sendStatus(200);
});
app.get("/settings", (req, res) => {
    res.send(settings);
});
let client = new (require('discord-rpc-revamp').Client)();
client.connect({ clientId: '1199262091752779777' }).catch(console.error);
client.on('ready', () => {
    client.setActivity({
        details: 'Radar Scope',
        state: 'Running the damn radar',
        startTimestamp: Date.now(),
        largeImageKey: "acid"
    }).then(() => console.log('Discord RPC Activity Set')).catch(console.error);
});
app.listen(6969);
