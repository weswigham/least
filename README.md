least
=======

A simple testing framework for lua with the least amount of bloat and dependencies possible.

####Using least
Make sure least.lua is in your package.path, then simply
```lua
local describe = require("least")
```
And start testing!

####Example
```lua
local describe = require("least")

describe("least lets you organize your tests by suite",function(_ENV)
    describe("least supports sub-suites and sub-suites with sub-suites, and so on",function()
        it("has basic assertions",function()
            assert(true)
        end)
        
        it("supports truthy/falsey/nil checks",function()
            assert.truthy(true)
            assert.falsey(false)
            assert.falsey(nil)
            assert.isNil(nil)
        end)
        
        it.should.fail("when truthy is given a false value",function()
            assert.truthy(false)
        end)
    end)
end)
```
You might notice that I import the module as the describe function; this is because the module conviently maps its call attribute to the least.describe function.

Additionally, a fake environment is created when calling your testing functions, giving them access to all of the functions below without the least namespace.

You may notice the _ENV argument to the topmost function; this is only required to create the fake environment in lua 5.2. Otherwise, it may be omitted.
####Functions
######least.describe
```lua
least.describe ( description, func )
least.suite    ( description, func )
```
In least, 'suite' and 'describe' are synonymous.

######least.it
```lua
least.test ( description, func )
least.it   ( description, func )
least.test.should.pass ( description, func )
least.it.should.pass   ( description, func )
```
As are 'test' and 'it'. You can use whichever fits your preference.

######least.it.should.fail
```lua
least.test.should.fail ( description, func )
least.it.should.fail   ( description, func )
```

######least.assert
```lua
least.assert ( statement )
least.assert.truthy ( statement )
```

######least.assert.falsy
```lua
least.assert.falsy ( statement )
```

######least.assert.isNil
```lua
least.assert.isNil ( statement )
```
