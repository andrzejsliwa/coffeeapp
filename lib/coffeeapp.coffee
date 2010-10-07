#!/usr/bin/env coffee
#
# CoffeeApp - coffee-script wrapper for CouchApp
# Copyright 2010 Andrzej Sliwa (andrzej.sliwa@i-tool.eu)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

exist = require('path').existsSync
joinPath = require('path').join
extName = require('path').extname
mkDir = require('fs').mkdirSync
readDir = require('fs').readdirSync
writeFile = require('fs').writeFileSync
readFile = require('fs').readFileSync
getStats = require('fs').statSync
coffeeCompile = require('coffee-script').compile
exec  = require('child_process').exec

padTwo = (number) ->
  result = if number < 10 then '0' else ''
  result + String(number)


getTimestamp = ->
  date = new Date()
  date.getFullYear() +
  padTwo(date.getMonth() + 1) +
  padTwo(date.getDate()) +
  padTwo(date.getHours() + 1) +
  padTwo(date.getMinutes() + 1) +
  padTwo(date.getSeconds() + 1)

printOutput = (stdout, stderr) ->
  console.log(stdout) if stdout.length > 0
  console.log(stderr) if stderr.length > 0



processRecursive = (currentDir, destination) ->
  fileList = readDir(currentDir)
  for fileName in fileList
    filePath = joinPath(currentDir, fileName)
    destFilePath = joinPath(destination, filePath)
    if getStats(filePath).isDirectory()
      unless fileName[0] == '.'
        mkDir(destFilePath, 0700)
        processRecursive(filePath, destination)
    else
      if extName(filePath) == '.coffee'
        console.log('processing ' + filePath + '...')
        writeFile(destFilePath.replace(/\.coffee$/, '.js'),
          coffeeCompile(readFile(filePath, encoding = 'utf8'), noWrap: yes).replace(/^\(/,'').replace(/\);$/, ''), encoding = 'utf8')
      else
        exec('cp ' + filePath + ' ' + destFilePath, (error, stdout, stderr) ->
          printOutput(stdout, stderr)
          if (error != null)
            console.log('exec error: ' + error)
        )

grindCoffee = ->
  releasesDir = '.releases'
  unless exist(releasesDir)
    console.log 'initialize ' + releasesDir + ' directory'
    mkDir(releasesDir, 0700)
  releasePath = joinPath(releasesDir, getTimestamp())
  mkDir(releasePath, 0700)
  processRecursive('.', releasePath)
  process.chdir(releasePath)
  exec('couchapp push', (error, stdout, stderr) ->
    printOutput(stdout, stderr)
    if (error != null)
      console.log('exec error: ' + error)
  )
  process.cwd()



console.log("CoffeeApp (v0.0.2) - simple coffee-script wrapper for CouchApp (http://couchapp.org)")
console.log("http://github.com/andrzejsliwa/coffeeapp\n")
if 'push' in process.argv
  console.log("Wrapping 'push' of couchapp")
  grindCoffee()
else
  options = ''
  for opt in process.argv
    options += " " + opt

  console.log("Calling couchapp")

  exec('couchapp' + options, (error, stdout, stderr) ->
    printOutput(stdout, stderr)
    if (error != null)
      console.log('exec error: ' + error)
  )

