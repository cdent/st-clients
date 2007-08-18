from distutils.core import setup
setup(name='socialtext',
      version='1.0',
      packages=[
        'socialtext'
      , 'socialtext.rest'
      , 'socialtext.buildbot'
      , 'socialtext.buildbot.process'
      , 'socialtext.buildbot.status'
      , 'socialtext.buildbot.steps'])
