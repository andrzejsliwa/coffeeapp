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
        writeFile(destFilePath, readFile(filePath, encoding = 'utf8'), encoding = 'utf8')

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
    console.log(stdout)
    console.log(stderr)
    if (error != null)
      console.log('exec error: ' + error)
  )
  process.cwd()


if 'push' in process.argv
  grindCoffee()
else
  options = ''
  for opt in process.argv
    options += " " + opt

  exec('couchapp' + options, (error, stdout, stderr) ->
    console.log(stdout)
    console.log(stderr)
    if (error != null)
      console.log('exec error: ' + error)
  )

