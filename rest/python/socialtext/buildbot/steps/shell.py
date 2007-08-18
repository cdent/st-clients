from socialtext.buildbot.process.buildstep import PrvLogObserver

from buildbot.steps.shell import ShellCommand


class PrvShellCommand(ShellCommand):

    def start(self):
        self.addLogObserver('stdio', PrvLogObserver(self))
        return ShellCommand.start(self)
