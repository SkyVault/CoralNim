from os import listdir
from os.path import isfile, join, realpath, dirname
from subprocess import call

SOURCE_DIR = dirname(realpath(__file__)) + "/../Coral/"
print(SOURCE_DIR)

files = [f for f in listdir(SOURCE_DIR) if isfile(join(SOURCE_DIR, f))]

for f in files:
    if f.endswith(".nim"):
        call(["nim"], )