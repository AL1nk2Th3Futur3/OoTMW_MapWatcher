import socket, threading, hashlib, time, os, json, random
from flask import Flask, request, render_template, Response
import socketio
from parsers import *

# Trying to keep console clutter to a minimum
import logging
log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)

app = Flask(__name__, static_url_path="")
app.config['TEMPLATES_AUTO_RELOAD'] = True
sio = socketio.Server(async_mode='threading')
app.wsgi_app = socketio.Middleware(sio, app.wsgi_app)

PLAYERS = {}
ROOMS = {}

def Client(conn, addr):
    with conn:
        # Create a unique player hash ID
        playerHash = hashlib.sha256(str(time.time).encode()).hexdigest() + hashlib.sha256(str(hash(conn)).encode()).hexdigest()
        playerHash = hashlib.sha256(playerHash.encode()).hexdigest()
        PLAYERS[playerHash] = {}

        conn.settimeout(15)
        while True:
            try:
                data = conn.recv(1024)
                print(data)
            except socket.timeout:
                print('Timed out')
                conn.close()
                break
            if not data: break
            message = data.decode().split(',')

            # Initial settings on join
            if message[0] == 'join':
                if message[5] in ROOMS[message[3]]['Players']:
                    ROOMS[message[3]]['Players'].remove(message[5])
                    ROOMS[message[3]]['Players'].append(playerHash)
                    PLAYERS[playerHash]['Id'] = playerHash
                    PLAYERS[playerHash]['Username'] = message[1]
                    PLAYERS[playerHash]['Colour'] = message[2]
                    PLAYERS[playerHash]['Room'] = message[3]
                    PLAYERS[playerHash]['Location'] = int(message[6])
                    PLAYERS[playerHash]['Items'] = [int(i) for i in message[7:31]]
                    PLAYERS[playerHash]['Equipment'] = get_ss(message[32]) + get_tb(message[31])
                    PLAYERS[playerHash]['Upgrades'] = get_up(message[33:37])
                    PLAYERS[playerHash]['QuestItems'] = get_qi(message[37:41])
                    PLAYERS[playerHash]['MaxHearts'] = int(message[41]) / 16
                    # PLAYERS[playerHash]['CurrentHearts'] = int(message[42])
                    PLAYERS[playerHash]['Rupees'] = int(message[43])
                    PLAYERS[playerHash]['Skulltulas'] = int(message[44])

                    sio.emit('sendPlayer', PLAYERS[playerHash], room=PLAYERS[playerHash]['Room'])
            # Update a player's location
            if message[0] == 'location':
                PLAYERS[playerHash]['Location'] = int(message[1])
                sio.emit(
                    'updateLocation',
                    {
                        'Id': PLAYERS[playerHash]['Id'],
                        'Location': PLAYERS[playerHash]['Location'],
                        'Colour': PLAYERS[playerHash]['Colour'],
                        'Username': PLAYERS[playerHash]['Username']
                    },
                    room=PLAYERS[playerHash]['Room']
                )

            # Update a player's items
            if message[0] == 'items':
                PLAYERS[playerHash]['Items'] = [int(i) for i in message[1:25]]
                sio.emit(
                    'updateItems',
                    {
                        'Id': PLAYERS[playerHash]['Id'],
                        'Items': PLAYERS[playerHash]['Items']
                    },
                    room=PLAYERS[playerHash]['Room']
                )

            # Update a player's equipment
            if message[0] == 'equipment':
                PLAYERS[playerHash]['Equipment'] = get_ss(message[2]) + get_tb(message[1])
                sio.emit(
                    'updateEquipment',
                    {
                        'Id': PLAYERS[playerHash]['Id'],
                        'Equipment': PLAYERS[playerHash]['Equipment']
                    },
                    room=PLAYERS[playerHash]['Room']
                )

            # Update a player's upgrades
            if message[0] == 'upgrades':
                PLAYERS[playerHash]['Upgrades'] = get_up(message[1:5])
                sio.emit(
                    'updateUpgrades',
                    {
                        'Id': PLAYERS[playerHash]['Id'],
                        'Upgrades': PLAYERS[playerHash]['Upgrades']
                    },
                    room=PLAYERS[playerHash]['Room']
                )

            # Update a player's quest items
            if message[0] == 'questitems':
                PLAYERS[playerHash]['QuestItems'] = get_qi(message[1:5])
                sio.emit(
                    'updateQuestItems',
                    {
                        'Id': PLAYERS[playerHash]['Id'],
                        'QuestItems': PLAYERS[playerHash]['QuestItems']
                    },
                    room=PLAYERS[playerHash]['Room']
                )

            # Update a player's max hearts
            if message[0] == 'maxhearts':
                PLAYERS[playerHash]['MaxHearts'] = int(message[1]) / 16
                sio.emit(
                    'updateMaxHearts',
                    {
                        'Id': PLAYERS[playerHash]['Id'],
                        'MaxHearts': PLAYERS[playerHash]['MaxHearts']
                    },
                    room=PLAYERS[playerHash]['Room']
                )

            # Update a player's rupees
            if message[0] == 'rupees':
                PLAYERS[playerHash]['Rupees'] = int(message[1])
                sio.emit(
                    'updateRupees',
                    {
                        'Id': PLAYERS[playerHash]['Id'],
                        'Rupees': PLAYERS[playerHash]['Rupees']
                    },
                    room=PLAYERS[playerHash]['Room']
                )

            # Update a player's skulltulas
            if message[0] == 'skulltulas':
                PLAYERS[playerHash]['Skulltulas'] = int(message[1])
                sio.emit(
                    'updateSkulltulas',
                    {
                        'Id': PLAYERS[playerHash]['Id'],
                        'Skulltulas': PLAYERS[playerHash]['Skulltulas']
                    },
                    room=PLAYERS[playerHash]['Room']
                )

        sio.emit('remPlayer', PLAYERS[playerHash], room=PLAYERS[playerHash]['Room'])
        print(ROOMS, PLAYERS)
        ROOMS[PLAYERS[playerHash]['Room']]['Players'].remove(playerHash)
        if len(ROOMS[PLAYERS[playerHash]['Room']]['Players']) == 0:
            del ROOMS[PLAYERS[playerHash]['Room']]
        del PLAYERS[playerHash]
        print(ROOMS, PLAYERS)
        print("Closed")


def SocketServer():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(('0.0.0.0', 50001))
        while True:
            sock.listen()
            conn, addr = sock.accept()
            t = threading.Thread(target=Client, args=(conn, addr))
            t.start()
            print(threading.active_count())

def RoomCheck(room, playerHash):
    time.sleep(1)
    if room in ROOMS:
        if playerHash in ROOMS[room]['Players']:
            ROOMS[room]['Players'].remove(playerHash)
            if len(ROOMS[room]['Players']) == 0:
                del ROOMS[room]

@app.route('/checkRoom', methods = ['GET'])
def check_room():
    room = request.args.get('room', type=str)
    password = request.args.get('password', type=str)
    if room in ROOMS:
        if ROOMS[room]['Password'] == password:
            playerHash = hashlib.sha256(str(time.time).encode()).hexdigest() + hashlib.sha256(str(random.randint(0,10000000)/1000000000).encode()).hexdigest()
            playerHash = hashlib.sha256(playerHash.encode()).hexdigest()
            ROOMS[room]['Players'].append(playerHash)
            t = threading.Thread(target=RoomCheck, args=(room, playerHash))
            t.start()
            return Response("Entered room,{}".format(playerHash), status=200)
        else:
            return Response("Password incorrect", status=200)
    else:
        playerHash = hashlib.sha256(str(time.time).encode()).hexdigest() + hashlib.sha256(str(random.randint(0,10000000)/1000000000).encode()).hexdigest()
        playerHash = hashlib.sha256(playerHash.encode()).hexdigest()
        ROOMS[room] = {
            'Password': password,
            'Players': [playerHash]
        }
        t = threading.Thread(target=RoomCheck, args=(room, playerHash))
        t.start()
        return Response("Room created,{}".format(playerHash), status=200)

@app.route('/getRooms', methods = ['GET'])
def get_rooms():
    return Response(json.dumps(list(ROOMS.keys())), status=200, mimetype='application/json')

@app.route('/getPlayers', methods = ['GET'])
def get_players():
    room = request.args.get('room', type=str)
    print(room in ROOMS)
    if room in ROOMS:
        players = {key:PLAYERS[key] for key in ROOMS[room]['Players']}
        return Response(json.dumps(players), status=200, mimetype='application/json')
    else:
        return Response(None, status=404, mimetype='application/json')

@app.route('/', methods = ['GET'])
def index():
    return render_template("index.html")

@sio.on('join_room')
def join_room(sid, room):
    sio.enter_room(sid=sid, room=room)
    # sio.emit("joined", {'data':'Room joined'}, room=room)

@sio.on('leave_room')
def leave_room(sid, room):
    sio.leave_room(sid=sid, room=room)

if __name__ == '__main__':
    SERVER = threading.Thread(target=SocketServer)
    SERVER.start()

    # Disable logging
    app.logger.disabled = True
    log = logging.getLogger('werkzeug')
    log.disabled = True

    # Run Flask
    app.run(threaded=True, host='0.0.0.0', port=8000)
