import socket, threading, hashlib, time, os
from flask import Flask, request, render_template, Response
import socketio

# Trying to keep console clutter to a minimum
import logging
log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)

# Holds all the information of the connected players
PLAYERS = {}

# Setup stuff for the web server
app = Flask(__name__, static_url_path="")
app.config['TEMPLATES_AUTO_RELOAD'] = True
sio = socketio.Server(async_mode='threading')
app.wsgi_app = socketio.Middleware(sio, app.wsgi_app)

# Function for the keepalive thread
def keepalive(conn, addr):
    with conn:
        conn.settimeout(3)
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
                    conn.sendall(b'pong' + b'\n')
                # If the client says the player's location has changed, update the PLAYERS dict and send it to the webserver
                if message[0] == b'location':
                    PLAYERS[playerHash]['Location'] = int(message[1])
                    sio.emit("updateMap",
                    {
                        "id": playerHash,
                        "location": PLAYERS[playerHash]['Location']
                    })
                # Used to set the initial data for the player on first connection, sends data to webserver
                if message[0] == b'username':
                    PLAYERS[playerHash]['Username'] = message[1].decode()
                    PLAYERS[playerHash]['Location'] = message[2].decode()
                    PLAYERS[playerHash]['Colour'] = message[3].decode()
                    print('User has connected:', PLAYERS[playerHash]['Username'])
                    sio.emit("socketConnected",
                    {
                        "id": playerHash,
                        "username": PLAYERS[playerHash]['Username'],
                        "location": PLAYERS[playerHash]['Location'],
                        "colour": PLAYERS[playerHash]['Colour']
                    })
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

# Send the entire player list to the webserver
@sio.on('getMap')
def my_event(data):
    sio.emit('sendMap', PLAYERS)

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
        decision = input("Save {}:{} for later use? ".format(HOST,PORT))
        if decision.lower() in ['y', 'yes', 'yeah', 'ye', 'oui']:
            with open("serverInfo.txt", 'w') as fil:
                fil.write("{},{}".format(HOST,PORT))
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
    app.run(threaded=True, host='0.0.0.0', port=80)
