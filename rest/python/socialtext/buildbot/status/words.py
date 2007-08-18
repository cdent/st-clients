from socialtext.buildbot.common import yamlPage

from twisted.application import internet

from buildbot.status import base
from buildbot.status.words import IRC, IrcStatusBot, IrcStatusFactory


class SocialtextIrcStatusBot(IrcStatusBot):

    def __init__(self, nickname, password, channels, status, categories,
            rester):
        IrcStatusBot.__init__(self, nickname, password, channels, status,
                categories)
        self.rester = rester

    def getSilly(self):
        return yamlPage(self.rester, 'silly')

    silly = property(getSilly)

    def command_SILLIES(self, user, reply, args):
        sillies = self.silly.keys()
        sillies.sort()
        for s in sillies:
            self.reply(reply, s)

    def getAllBuilders(self):
        """
        Our version doesn't sort the names

        @rtype: list of L{buildbot.process.builder.Builder}
        """
        names = self.status.getBuilderNames(categories=self.categories)
        builders = [self.status.getBuilder(n) for n in names]
        return builders

    def build_commands(self):
        """ Build a list of cammands based on our class dict, and our parent's class dict
        """
        commands_dict = {}
        for k in (self.__class__.__dict__.keys() + IrcStatusBot.__dict__.keys()):
            if k.startswith('command_'):
                commands_dict[k[8:].lower()] = None
        commands = commands_dict.keys()
        commands.sort()
        return commands


class SocialtextIrcStatusFactory(IrcStatusFactory):

    protocol = SocialtextIrcStatusBot

    def __init__(self, nickname, password, channels, categories, rester):
        IrcStatusFactory.__init__(self, nickname, password, channels, categories)
        self.rester = rester

    def buildProtocol(self, address):
        p = self.protocol(self.nickname, self.password,
                          self.channels, self.status,
                          self.categories, self.rester)
        p.factory = self
        p.status = self.status
        p.control = self.control
        self.p = p
        return p


class SocialtextIRC(IRC):

    def __init__(self, host, nick, channels, rester, port=6667, allowForce=True,
                 categories=None, password=None):
        base.StatusReceiverMultiService.__init__(self)

        assert allowForce in (True, False) # TODO: implement others

        # need to stash these so we can detect changes later
        self.host = host
        self.port = port
        self.nick = nick
        self.channels = channels
        self.rester = rester
        self.password = password
        self.allowForce = allowForce
        self.categories = categories

        # need to stash the factory so we can give it the status object
        self.f = SocialtextIrcStatusFactory(self.nick, self.password,
                                            self.channels, self.categories,
                                            self.rester)

        c = internet.TCPClient(host, port, self.f)
        c.setServiceParent(self)


