import re

from socialtext.buildbot.common import nlwShellStep, multiProveStep, proveStep
from socialtext.buildbot.steps.source import SocialtextSVN

from buildbot.process.factory import s, BuildFactory


def stSanityFactory(repo):
    sanityTests = ['compile', 'case-conflict', 'copyright', 'tests', 'programs', 'pod', 'pod-coverage' ]

    return SocialtextBuildFactory(repo,
        [proveStep(test) for test in sanityTests])

def stQuickFactory(repo):
    return SocialtextQuickFactory( repo, [] )

def stTestFactory(repo):
    return SocialtextBuildFactory( repo,
        [nlwShellStep('run tests',
            'find t -name \\*.t -not -regex .\\*t/live.\\* -print0 | xargs -0 prove -lvs')])

def stLiveFactory(repo):
    return SocialtextLiveTestFactory( repo,
        [nlwShellStep('run tests',
            'find t/live -name \\*.t -print0 | xargs -0 prove -lvs')])


class SocialtextBuildFactory(BuildFactory):

    def __init__(self, repo, steps=None):
        self.basicSteps = [

        # Checkout
        s( SocialtextSVN
         , mode='update'
         , baseURL=repo
         , defaultBranch='/trunk'
         ),

        # Fix tarball (harmless on nonMacs)
        nlwShellStep( 'fix help tarball'
                    , 'dev-bin/fix-help-tarball-for-mac'
                    ),

        # Stop test servers; clear cached fixtures.
        nlwShellStep( 'cleanup'
                    , 'if [ -d t/tmp ]; then dev-bin/nlwctl -t stop; rm -r t/tmp*; fi'
                    ),

        # Configure.
        nlwShellStep( 'configure'
                    , './configure --dev=1 --apache-proxy=1 --server-admin=support@socialtext.com'
                    )]

        BuildFactory.__init__(self, self.basicSteps + steps)


class IntrospectableTestFactory(SocialtextBuildFactory):

    def newBuild(self, request):
        """ Introspect the request, and try on only apply tests pertinent to
        changed source files (derived from request.allChanges())
        """
        b = SocialtextBuildFactory.newBuild(self, request)
        changed_files = {}
        for c in b.allChanges():
            for f in c.files:
                changed_files[f] = None

        b.setSteps(self.deriveTestsFromChanges(changed_files))

        return b


class SocialtextQuickFactory(IntrospectableTestFactory):

    def deriveTestsFromChanges(self, changed_files):
        steps = []

        for file in changed_files.keys():

            normal_file = re.match('^nlw/lib', file)
            test_file = re.match('^nlw/t/(.*)\.t$', file)

            if normal_file:
                steps.append(multiProveStep(file))
            elif test_file:
                steps.append(proveStep(test_file.group(1)))

        return self.basicSteps + steps


class SocialtextLiveTestFactory(IntrospectableTestFactory):

    def deriveTestsFromChanges(self, changed_files):
        # XXX: Unimplemented so far.
        return self.steps


