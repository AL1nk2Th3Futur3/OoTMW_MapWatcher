from flask import Flask, request, render_template, Response
from flask_socketio import SocketIO, send, emit, join_room, leave_room
import random, hashlib, time, json

app = Flask(__name__, static_url_path="")
# Remember to change this... Or remove it entirely actually
app.config['SECRET_KEY'] = "A4A4BB55B152833E72E5F3B85CAA30F61E99D4260063F723E7993323A6AC95B6"
app.secret_key = "A4A4BB55B152833E72E5F3B85CAA30F61E99D4260063F723E7993323A6AC95B6"
app.config['TEMPLATES_AUTO_RELOAD'] = True
socketio = SocketIO(app)

import csv

with open("Locations.csv") as fil:
    reader = csv.reader(fil)
    LOCATIONS = []
    for row in reader:
        LOCATIONS.append(row[1])

sessions = {}

# @socketio.on('my event')
# def my_event(data):
#     print("Connected: {}".format(data))

@app.route("/login", methods=['GET'])
def login():
    if request.method == 'GET':
        # id = request.args.get('id', type=float)
        # id = 1
        id = hashlib.sha256(str(time.time).encode()).hexdigest() + hashlib.sha256(str(random.randint(0,1000000000)).encode()).hexdigest()
        id = hashlib.sha256(id.encode()).hexdigest()
        sessions[str(id)] = {}
        sessions[str(id)]['username'] = request.args.get('username', type=str)
        sessions[str(id)]['password'] = request.args.get('password', type=str)
        sessions[str(id)]['roomname'] = request.args.get('roomname', type=str)
        sessions[str(id)]['location'] = request.args.get('location', type=int)
        sessions[str(id)]['colour'] = "rgb({}, {}, {})".format(
            random.randint(0,255),
            random.randint(0,255),
            random.randint(0,255)
        )
        socketio.emit("createdot", {
            'player': sessions[str(id)]['username'],
            'locationNum': request.args.get('location', type=int),
            'id': id,
            'colour': sessions[str(id)]['colour']
        })
        # print(session['username'], session['password'], session['roomname'])

        return Response(id, status=200)

@app.route("/updatemap", methods=['GET'])
def updatemap():
    print(sessions)
    id = request.args.get('id', type=str)
    if 'username' not in sessions[str(id)]:
        print('No username')
        return Response(None, status=404)
    if 'password' not in sessions[str(id)]:
        print('No password')
        return Response(None, status=404)
    if 'roomname' not in sessions[str(id)]:
        print('No roomname')
        return Response(None, status=404)

    print(id)

    if request.method == 'GET':
        sessions[str(id)]['location'] = request.args.get('location', type=int)
        locationNum = request.args.get('location', type=int)
    socketio.emit("updatemap", {
        'player': sessions[str(id)]['username'],
        'locationNum': locationNum,
        'id': id
    })
    # return "You've entered {}".format(LOCATIONS[locationNum])
    return Response(None, status=200)

@app.route('/getsession', methods=['GET'])
def getsession():
    return Response(json.dumps(sessions), status=200, mimetype='application/json')

@app.route('/')
def index():
    return render_template("index.html")

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0')
