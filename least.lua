local least = {}

local active_suites = {}

local esc = string.char(27)
local color = {
    reset   = esc.."[0m",
    bold   = esc.."[1m",
    dim     = esc.."[2m",
    under   = esc.."[4m",
    blink   = esc.."[5m",
    rev     = esc.."[7m",
    hiddn   = esc.."[8m",
    black   = esc.."[30m",
    r       = esc.."[31m",
    g       = esc.."[32m",
    y       = esc.."[33m",
    b       = esc.."[34m",
    m       = esc.."[35m",
    c       = esc.."[36m",
    w       = esc.."[37m"
}

if not ((package.config:sub(1,1)=='\\' and os.getenv("ANSICON")) or package.config:sub(1,1)=='/') then --we lack console color support
    for k,v in pairs(color) do
        color[k] = ""
    end
end

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

least.quiet = false

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
setmetatable(least.test.should,__test)
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
    
    if setfenv then --Lua 5.1, yay~
        local fake = {} 
        setmetatable(fake,{
            __index = _G
        })
        for k,v in pairs(least) do
            fake[k] = v
        end
        setfenv(func,fake)
        func()
    else --We need the topmost level to have _ENV as a named argument.. bleh
        local fake = {} 
        setmetatable(fake,{
            __index = _G
        })
        for k,v in pairs(least) do
            fake[k] = v
        end
        func(fake)
    end
    
    unhook(self)
    
    local out = ""
    local bull = "•"
    local fbull = color.r..color.bold..bull..color.reset
    local pbull = color.g..bull..color.reset
    if self.fails[1] then
        print(color.r.."Suite Failed"..color.reset.." - "..self.desc.."\n"..color.y.."Failed Test(s):"..color.reset)
        for k,v in ipairs(self.fails) do
            out = out..fbull
            print("\t"..color.b..v.desc.."\n\t\t"..color.y.."Failed Asserts:"..color.reset)
            for k,test in ipairs(v.fails) do
                print("\t\t"..(test.line or "Subsuite Failure"))
            end
            if v.error then 
                print("\t"..color.r..color.bold.."Errors: "..color.reset..v.error)
            end
        end
    end
    
    for k,v in ipairs(self.sucesses) do
        out = out..pbull
    end
    out = out .. (" ("..(#self.sucesses).."/"..(#self.sucesses+#self.fails)..")")
    out = "\t"..out
    
    if not least.quiet then
        print(out)
    end
    
    --Make subsuites count as one 'dot' and prevent extra, unneeded prints
    for k,v in ipairs(active_suites) do
        if v~=self then
            if self.fails[1] then
                table.insert(v.fails, self)
            else
                table.insert(v.sucesses, self)
            end
        end
    end
    
    return self
end

least.describe = least.suite
least.it = least.test

local __suite = {
    __call = function(self, desc, func)
        return least.suite(desc, func)
    end
}
setmetatable(least,__suite)

return least