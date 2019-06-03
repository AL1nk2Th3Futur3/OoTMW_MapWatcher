import socket, threading, hashlib, time, os, json
from flask import Flask, request, render_template, Response
import socketio

# Trying to keep console clutter to a minimum
import logging
log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)

# Holds all the information of the connected players
PLAYERS = {}

# Holds the optional password
PASSWORD = b''

# Setup stuff for the web server
app = Flask(__name__, static_url_path="")
app.config['TEMPLATES_AUTO_RELOAD'] = True
sio = socketio.Server(async_mode='threading')
app.wsgi_app = socketio.Middleware(sio, app.wsgi_app)

# Handle Sword/Shield equipment
def get_ss(num):
    tmp = []
    num = bin(int(num)).replace("0b", "")
    if len(num) != 7:
        num = ("0"*(7-len(num))) + num
    tmp.append(59) if num[6] == '1' else tmp.append(255)
    tmp.append(60) if num[5] == '1' else tmp.append(255)
    tmp.append(61) if num[4] == '1' else tmp.append(255)
    tmp.append(62) if num[2] == '1' else tmp.append(255)
    tmp.append(63) if num[1] == '1' else tmp.append(255)
    tmp.append(64) if num[0] == '1' else tmp.append(255)
    return tmp

# Handle Tunic/Boots equipment
def get_tb(num):
    tmp = []
    num = bin(int(num)).replace("0b", "")
    if len(num) != 7:
        num = ("0"*(7-len(num))) + num
    tmp.append(65) if num[6] == '1' else tmp.append(255)
    tmp.append(66) if num[5] == '1' else tmp.append(255)
    tmp.append(67) if num[4] == '1' else tmp.append(255)
    tmp.append(68) if num[2] == '1' else tmp.append(255)
    tmp.append(69) if num[1] == '1' else tmp.append(255)
    tmp.append(70) if num[0] == '1' else tmp.append(255)
    return tmp

# Handle Upgrades
def get_up(num):
    tmp = ""
    for n in num:
        try:
            tmp += bin(int(n)).replace('0b', '')
        except:
            pass
    num = tmp
    tmp = []
    if len(num) != 23:
        num = ("0"*(23-len(num))) + num
    # Quiver
    if num[22] == '1':
        tmp.append(74)
    elif num[21] == '1':
        tmp.append(75)
    elif num[20] == '1':
        tmp.apend(76)
    else:
        tmp.append(255)
    # Bomb Bag
    if num[19] == '1':
        tmp.append(77)
    elif num[18] == '1':
        tmp.append(78)
    elif num[17] == '1':
        tmp.apend(79)
    else:
        tmp.append(255)
    # Gauntlet
    if num[16] == '1':
        tmp.append(80)
    elif num[15] == '1':
        tmp.append(81)
    elif num[14] == '1':
        tmp.apend(82)
    else:
        tmp.append(255)
    # Scale
    if num[13] == '1':
        tmp.append(83)
    elif num[12] == '1':
        tmp.append(84)
    else:
        tmp.append(255)
    # Wallet
    if num[10] == '1':
        tmp.append(86)
    elif num[9] == '1':
        tmp.append(87)
    else:
        tmp.append(255)
    # Bullet Bag?
    if num[5] == '1':
        tmp.append(71)
    elif num[4] == '1':
        tmp.append(72)
    elif num[3] == '1':
        tmp.apend(73)
    else:
        tmp.append(255)

    return tmp

# Handle Quest Items
def get_qi(num):
    tmp = ""
    for n in num:
        tmp += bin(int(n)).replace('0b', '')
    num = tmp
    tmp = []
    if len(num) != 32:
        num = ("0"*(32-len(num))) + num
    # Normal songs
    for i in range(6):
        tmp.append(96+i) if num[19-i] == '1' else tmp.append(255)
    # Warp songs
    for i in range(6):
        tmp.append(90+i) if num[25-i] == '1' else tmp.append(255)
    # Meallions
    for i in range(6):
        tmp.append(102+i) if num[31-i] == '1' else tmp.append(255)
    # Stones
    for i in range(3):
        tmp.append(108+i) if num[13-i] == '1' else tmp.append(255)
    # Stone of Agony and Geurudo Card
    for i in range(2):
        tmp.append(111+i) if num[10-i] == '1' else tmp.append(255)

    return tmp


# Function for the keepalive thread
def keepalive(conn, addr):
    with conn:
        conn.settimeout(6)
        # Create a unique player hash ID
        playerHash = hashlib.sha256(str(time.time).encode()).hexdigest() + hashlib.sha256(str(hash(conn)).encode()).hexdigest()
        playerHash = hashlib.sha256(playerHash.encode()).hexdigest()
        PLAYERS[playerHash] = {}

        # Function loop
        while True:
            try:
                # Wait until data is received and then deal with it
                data = conn.recv(1024)
                if not data: break
                message = data.split(b',')
                # If ping send pong, works to ensure the connection is still good
                if message[0] == b'ping':
                    # conn.sendall(b'pong' + b'\n')
                    pass
                # If the client says the player's location has changed, update the PLAYERS dict and send it to the webserver
                if message[0] == b'location':
                    PLAYERS[playerHash]['Location'] = int(message[1])
                    sio.emit("updateMap",
                    {
                        "id": playerHash,
                        "location": PLAYERS[playerHash]['Location']
                    })
                # Used to handle getting new items
                if message[0] == b'items':
                    PLAYERS[playerHash]['Items'] = [int(i) for i in message[1:25]]
                    sio.emit('sendPlayer', {'data':PLAYERS[playerHash], 'hash':playerHash})
                # Used to handle getting new equipment
                if message[0] == b'equipment':
                    PLAYERS[playerHash]['Equipment'] = get_ss(message[2]) + get_tb(message[1])
                    sio.emit('sendPlayer', {'data':PLAYERS[playerHash], 'hash':playerHash})
                # Used to handle getting upgrades
                if message[0] == b'upgrades':
                    PLAYERS[playerHash]['Upgrades'] = get_up(message[1:5])
                    sio.emit('sendPlayer', {'data':PLAYERS[playerHash], 'hash':playerHash})
                # Used to handle getting quest items
                if message[0] == b'questitems':
                    PLAYERS[playerHash]['QuestItems'] = get_qi(message[1:5])
                    sio.emit('sendPlayer', {'data':PLAYERS[playerHash], 'hash':playerHash})
                # Used to handle getting a new heart
                if message[0] == b'maxhearts':
                    PLAYERS[playerHash]['Maxhearts'] = int(message[1]) / 16
                    sio.emit('sendPlayer', {'data':PLAYERS[playerHash], 'hash':playerHash})
                # Used to handle getting and losing rupees
                if message[0] == b'rupees':
                    PLAYERS[playerHash]['Rupees'] = int(message[1])
                    sio.emit('sendPlayer', {'data':PLAYERS[playerHash], 'hash':playerHash})
                # Used to handle getting skulltuas
                if message[0] == b'skulltulas':
                    PLAYERS[playerHash]['Skulltulas'] = int(message[1])
                    sio.emit('sendPlayer', {'data':PLAYERS[playerHash], 'hash':playerHash})
                # Used to set the initial data for the player on first connection, sends data to webserver
                if message[0] == b'username':
                    # Check to see if provided password matches
                    if message[30] != PASSWORD:
                        return
                    PLAYERS[playerHash]['Username'] = message[1].decode()
                    PLAYERS[playerHash]['Location'] = message[2].decode()
                    PLAYERS[playerHash]['Colour'] = message[3].decode()
                    PLAYERS[playerHash]['Items'] = [int(i) for i in message[4:28]]
                    PLAYERS[playerHash]['Equipment'] = get_ss(message[28]) + get_tb(message[29])
                    PLAYERS[playerHash]['Upgrades'] = get_up(message[31:35])
                    PLAYERS[playerHash]['QuestItems'] = get_qi(message[35:39])
                    PLAYERS[playerHash]['Maxhearts'] = int(message[39]) / 16
                    PLAYERS[playerHash]['Rupees'] = int(message[41])
                    PLAYERS[playerHash]['Skulltulas'] = int(message[42])
                    print('User has connected:', PLAYERS[playerHash]['Username'])
                    sio.emit("socketConnected", {'data':PLAYERS[playerHash], 'hash':playerHash})

            # If there's an error of any type, break out of the loop and kill the thread
            except Exception as e:
                print(e)
                break
        # Send a disconnected message and clean up the player's data
        sio.emit("socketDisconnected", {"id": playerHash})
        print(PLAYERS[playerHash]['Username'], "has disconnected")
        del PLAYERS[playerHash]

# Listens for connections to the server
def listenForConnections():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind((HOST, PORT))
        # When a new connection is made, create a new keepalive thread for it
        while True:
            sock.listen()
            conn, addr = sock.accept()
            t = threading.Thread(target=keepalive, args=(conn, addr))
            t.start()

# Render the main html page
@app.route('/')
def index():
    return render_template("index.html")

# Send player data
@app.route('/getPlayer', methods = ['GET'])
def get_player():
    try:
        playerid = request.args.get('playerid', type=str)
        return Response(json.dumps(PLAYERS[playerid]), status=200, mimetype='application/json')
    except Exception as e:
        print(e)
        return Response(None, status=404)

# Send the entire player list to the webserver
@app.route('/getMap', methods = ['GET'])
def get_map():
    try:
        return Response(json.dumps(PLAYERS), status=200, mimetype='application/json')
    except Exception as e:
        print(e)
        return Response(None, status=404)

# Main function
if __name__ == '__main__':
    # Get Host and Port either from user input or file if exists
    if os.path.exists("serverInfo.txt"):
        print("serverInfo.txt found. Loading saved IP Address and Port...")
        with open("serverInfo.txt") as fil:
            HOST, PORT = fil.read().split(",")[:2]
        PORT = int(PORT)
        print("Host and port loaded...\n{}:{}".format(HOST,PORT))
    else:
        try:
            HOST = HOST = input("Enter your IP Address (Default 0.0.0.0): ")
            if HOST == "":
                HOST = '0.0.0.0'
        except:
            HOST = '0.0.0.0'
        try:
            PORT = int(input("Enter your desired port (Default 50001): "))
            if PORT == "":
                PORT = 50001
        except:
            PORT = 50001
        try:
            PASSWORD = bytes(input("Enter a password (Default none): ").encode())
        except Exception as e:
            print(e)
            PASSWORD = b''
        decision = input("Save {}:{} for later use? ".format(HOST,PORT))
        if decision.lower() in ['y', 'yes', 'yeah', 'ye', 'oui']:
            with open("serverInfo.txt", 'w') as fil:
                fil.write("{},{},{}".format(HOST,PORT,PASSWORD))
            print("Server info saved for later reuse...\nStarting server now...")

    print("")

    # Start server thread
    SERVER = threading.Thread(target=listenForConnections)
    SERVER.start()

    # Disable logging
    app.logger.disabled = True
    log = logging.getLogger('werkzeug')
    log.disabled = True

    # Run Flask
    app.run(threaded=True, host='0.0.0.0', port=8000)
