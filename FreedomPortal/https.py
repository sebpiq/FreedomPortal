import os
import cherrypy

current_dir = os.path.dirname(__file__)
app_root_dir = os.path.abspath(os.path.join(current_dir, '..'))
cert_dir = os.path.join(app_root_dir, 'certs')


class _Server(object):

    def __init__(self, *args, **kwargs):
        self.https_redirect_url = kwargs.get('https_redirect_url')
        del kwargs['https_redirect_url']
        super(_Server, self).__init__(*args, **kwargs)

    @cherrypy.expose
    def default(self,*args,**kwargs):
        raise cherrypy.HTTPRedirect(self.https_redirect_url)


def start(https_port=443, https_redirect_url='http://192.168.8.1'):
    server_config = {
        'server.socket_host': '0.0.0.0',
        'server.socket_port': https_port,
        'server.ssl_module': 'builtin',
        'server.ssl_certificate': os.path.join(cert_dir, 'cert.pem'),
        'server.ssl_private_key': os.path.join(cert_dir, 'privkey.pem')
    }

    cherrypy.config.update(server_config)
    cherrypy.quickstart(_Server(https_redirect_url=https_redirect_url))