import yaml

from socialtext.buildbot.steps.shell import PrvShellCommand

from buildbot.process.factory import s


def yamlPage(rester, name):
    return yaml.load(rester.get_page(name).replace('.pre\n', ''))

def nlwShellStep(name, command):
    return s(PrvShellCommand,
            workdir='build/nlw',
            description=name,
            command=command)

def proveStep(test):
    path='t/%s.t' % test

    return s(PrvShellCommand,
            workdir='build/nlw',
            description="test: %s" % test,
            command='if [ -e %s ]; then prove -lv %s; else true; fi' % (path, path))

def multiProveStep(pm_file):
    test_pat=re.sub('^nlw/lib/', 't/', re.sub('\.pm$', '*.t', pm_file))

    return s(PrvShellCommand,
            workdir='build/nlw',
            description="tests for %s" % pm_file,
            command='''perl -e 'for (glob "%s") { $fails += system "prove -lv $_" } exit $fails' ''' % test_pat)

