import bottle

def start(bottle_app, http_port=80, public_dir=None, index_file_name=None):

    if public_dir:
        @bottle.route('/assets/<path:path>')
        def assets(path):
            return bottle.static_file(path, root=public_dir)

    if index_file_name:
        @bottle.route('<url:re:.*>', method='GET')
        def index(url):
            return bottle.static_file(index_file_name, root=public_dir)

    bottle.run(app=bottle_app, server='cherrypy', port=http_port, host='0.0.0.0')