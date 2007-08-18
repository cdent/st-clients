import re

from buildbot.process.buildstep import LogLineObserver


class PrvLogObserver(LogLineObserver):
    """
    t/foo.....1/3
    ok
    ok
    not ok
    Failed Test        Stat Wstat Total Fail  Failed  List of Failed
    -------------------------------------------------------------------------------
    t/Socialtext/CLI.t   79 20224    ??   ??       %  ??
    t/Socialtext/Searc   79 20224    ??   ??       %  ??
    """

    seenFailed = False

    def __init__(self, step):
        self.step = step
        self.testOut = {}
        self.inTest = None
        LogLineObserver.__init__(self)

    def outLineReceived(self, line):
        if self.seenFailed:
            if line.startswith('t/'):
                testname = re.sub('\.t$', '', re.sub('^t/', '', re.split('\s+', line)[0]))
                # testname might be truncated, so we'd like to find *one*
                # testname in our testOut dict that matches.
                log = self.testOut.get(testname, None)
                if log is None:
                    seen = 0
                    for k in self.testOut.keys():
                        if k.startswith(testname):
                            seen += 1
                            log = self.testOut[k]
                    assert(seen == 1)
                self.step.addCompleteLog(testname, ''.join(log))
        elif line.startswith('Failed Test'):
            self.seenFailed = True
        elif line.startswith('All tests successful.'):
            self.inTest = None
        else:
            match = re.match('^t/(.+?)\.\.', line)
            if match:
                self.inTest = match.group(1)
            if self.inTest:
                self.testOut.setdefault(self.inTest, []).append(line)
