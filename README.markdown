### CoffeeApp -- coffee-script wrapper for CouchApp

### Installing

Prerequisites: CoffeeScript requires Node.js (<http://nodejs.org/>), Npm (http://npmjs.org/)

Get CoffeeApp:

    git clone git://github.com/andrzejsliwa/coffeeapp.git

Build Jake:

    cd coffeeapp && make && sudo make install

### Installing with [npm](http://npmjs.org/)

    npm install coffeeapp

Or, get the code, and `npm link` in the code root.

### Basic usage

    coffeeapp [couchapp options]


### Description

    CoffeeApp is a simple wrapper for couchapp command.
    CoffeeApp overide normal push behavoir, by adding .releases directory which contain deployment snapshots
    While files are copied to release snapshot... coffee-script files (.coffee) are converted on the fly to
    java-script (.js) files.

    .releases directory should be added to .gitignore or .hgignore or whatever you have using to prevent versioning.


### Author

Andrzej Sliwa, andrzej.sliwa@i-tool.eu
