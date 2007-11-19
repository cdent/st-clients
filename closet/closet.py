
"""Configuration for closet, a generic web store for content 
objects."""

# where do our servers run
host_url = 'http://0.0.0.0'

# on what ports
poster_port = 8000
putter_port = 8001
getter_port = 8002

# what are their urls
poster_server = host_url + ':' + str(poster_port) + '/'
putter_server = host_url + ':' + str(putter_port) + '/'
getter_server = host_url + ':' + str(getter_port) + '/'

# where are we putting stuff
file_store = 'storage/'

