from socialtext.buildbot.common import yamlPage

from buildbot.scheduler import AnyBranchScheduler


class RuntimeBranchScheduler(AnyBranchScheduler):

    def __init__(self, name, rester, treeStableTimer, builderNames,
                 fileIsImportant=None):
        self.rester = rester
        AnyBranchScheduler.__init__( self
                                   , name=name
                                   , branches=None
                                   , treeStableTimer=treeStableTimer
                                   , builderNames=builderNames
                                   , fileIsImportant=fileIsImportant
                                   )

    def addChange(self, change):
        self.branches = yamlPage(self.rester, 'branches')
        AnyBranchScheduler.addChange(self, change)
