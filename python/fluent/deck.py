import collections

Card = collections.namedtuple("Card", ["rank", "suit"])

House = collections.namedtuple("House", ["number", "street"])
me = House(141, "Comstock Pl")
me = House(number=141, street="Comstock Pl")
