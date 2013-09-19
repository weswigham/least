local least = {}

local active_suites = {}

local active_test

local function getstackplace()
    local stack = debug.traceback()
    local res
    for line in stack:gmatch("[^\r\n]+") do
        for cap in line:gmatch(".*.lua:%d+: in function <.*.lua:%d+>") do
            res = line
        end
    end
    return res
end

least.assert = {}
least.assert.isNil = function(statement)
    local result = {}
    result.line = getstackplace()
    if statement==nil then
        table.insert(active_test.sucesses,result)
    else
        table.insert(active_test.fails,result)
        active_test.passed = false
    end
end
least.assert.falsey = function(statement)
    local result = {}
    result.line = getstackplace()
    if not statement then
        table.insert(active_test.sucesses,result)
    else
        table.insert(active_test.fails,result)
        active_test.passed = false
    end
end
least.assert.truthy = function(statement)
    local result = {}
    result.line = getstackplace()
    if statement then
        table.insert(active_test.sucesses,result)
    else
        table.insert(active_test.fails,result)
        active_test.passed = false
    end
    return result
end
local __assert = {
    __call = function(self, statement)
        return least.assert.truthy(statement)
    end
}
setmetatable(least.assert,__assert)

least.test = {}
least.test.should = {}
least.test.should.pass = function(desc, func)
    self = {}
    self.desc = desc
    self.sucesses = {}
    self.fails = {}
    self.passed = true
    
    active_test = self
    
    local good, err = pcall(func)
    if not good then
        self.passed = false
        self.error = err
    end
    
    for k,v in ipairs(active_suites) do
        if self.passed then
            table.insert(v.sucesses,self)
        else
            table.insert(v.fails,self)
        end
    end
    
    active_test = nil
end
least.test.should.fail = function(desc, func)
    self = {}
    self.desc = desc
    self.sucesses = {}
    self.fails = {}
    self.passed = true
    
    active_test = self
    
    local good, err = pcall(func)
    if not good then
        self.passed = false
        self.error = err
    end
    
    for k,v in ipairs(active_suites) do
        if self.passed then
            table.insert(v.fails,self)
        else
            table.insert(v.sucesses,self)
        end
    end
    
    active_test = nil
end
local __test = {
    __call = function(self, desc, func)
        return least.test.should.pass(desc, func)
    end
}
setmetatable(least.test,__test)

local function hook(suite)
    table.insert(active_suites, suite)
end

local function unhook(suite)
    for k,v in ipairs(active_suites) do
        if v==suite then
            table.remove(active_suites, k)
            return
        end
    end
end


least.suite = function(desc, func)
    local self = {}
    self.desc = desc
    self.sucesses = {}
    self.fails = {}
    
    hook(self)
    function closure()
        local describe,suite,test,it = least.suite,least.suite,least.test,least.test
        func()
    end
    unhook(self)
    
    if self.fails[1] then
        print("Suite Failed - "..self.desc.."\nFailed Test(s):")
        for k,v in ipairs(self.fails) do
            print("\t"..v.desc.."\n\t\tFailed Asserts:")
            for k,test in ipairs(v.fails) do
                print("\t\t"..test.line)
            end
            if v.error then 
                print("\tErrors: "..v.error)
            end
        end
    end
    
    return self
end

local __suite = {
    __call = function(self, desc, func)
        return least.suite(desc, func)
    end
}
setmetatable(least,__suite)

least.describe = least.suite
least.it = least.test

return least