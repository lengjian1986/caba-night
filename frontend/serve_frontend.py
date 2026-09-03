from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()


if __name__ == '__main__':
    handler = partial(NoCacheHandler, directory='build/web')
    ThreadingHTTPServer(('0.0.0.0', 20222), handler).serve_forever()
