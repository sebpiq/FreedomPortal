import bottle

import server_common

def start(bottle_app, http_port=80):
    bottle.run(app=bottle_app, server='cherrypy', port=http_port, host='0.0.0.0')