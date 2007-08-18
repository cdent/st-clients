from buildbot.steps.source import SVN


class SocialtextSVN(SVN):

    def startVC(self, branch, revision, patch):
        SVN.startVC(self, branch, revision, patch)
        for d in [self.description, self.descriptionDone]:
            try:
                d.remove("[branch]")
                d.append(branch)
            except ValueError:
                pass
