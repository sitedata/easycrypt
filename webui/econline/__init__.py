# --------------------------------------------------------------------
import os, signal, atexit, subprocess as sp

# --------------------------------------------------------------------
__all__ = ['main']

# --------------------------------------------------------------------
def _routing(config):
    config.add_route('home' , '/')
    config.add_route('tryme', '/tryme')

# --------------------------------------------------------------------
def main(global_config, **settings):
    from pyramid.config import Configurator

    signal.signal(signal.SIGTERM, lambda : sys.exit())
    config = Configurator(settings=settings)
    start_backend(settings.get('econline.engine', None))
    config.include('.renderer.pyramid_genshi')
    config.add_static_view('static', 'static', cache_max_age=3600)
    config.include(_routing)
    config.scan()

    return config.make_wsgi_app()

main.process = None

# --------------------------------------------------------------------
def start_backend(bind):
    if bind is None:
        bind = 'localhost:8090'

    if main.process is not None:
        return

    from pkg_resources import resource_filename, Requirement

    backend = Requirement.parse('econline')
    backend = resource_filename(backend, 'econline/backend/start-backend')

    def preexec():
        signal.signal(signal.SIGINT, signal.SIG_IGN)
        os.chdir(os.path.dirname(backend))

    main.process = sp.Popen([backend, bind], preexec_fn = preexec)

# --------------------------------------------------------------------
def kill_backend():
    if main.process is not None:
        main.process.kill()
        main.process.wait()
        main.process = None

# --------------------------------------------------------------------
atexit.register(kill_backend)
