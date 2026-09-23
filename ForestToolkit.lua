--[[ 🌲 FOREST TOOLKIT v3.4.3 — Complete ]]
local P,R,W,RS = game:GetService("Players"),game:GetService("RunService"),
                 game:GetService("Workspace"),game:GetService("ReplicatedStorage")
local UIS,CG,TS,LG = game:GetService("UserInputService"),game:GetService("CoreGui"),
                     game:GetService("TweenService"),game:GetService("Lighting")
local HS = game:GetService("HttpService")
local TServ = game:GetService("TeleportService")
local plr = P.LocalPlayer
local unpack = table.unpack or unpack

local C = {
    stealth=true,spoofProps=true,blockRemotes=true,safeTP=true,
    killAura=false,killRange=150,killDelay=0.42,aimAssist=true,
    killMiss=0.08,killBreak=45,
    chopAura=false,chopRange=150,chopDelay=0.36,chopBig=true,
    chopMiss=0.05,chopBreak=60,
    stun=false,stunRange=30,entityGod=false,antiFling=false,
    bringItem=false,bringRange=120,bringDelay=0.7,bringAll=false,bringFilter="all",
    bringSpeed=35,
    autoFire=false,fireRange=100,fireDelay=2,
    autoCook=false,autoPlant=false,plantCount=5,autoScrap=false,autoCompress=false,autoCraft=false,
    autoCollect=false,collectFlowers=true,collectGold=true,
    autoOpenChest=false,chestRange=50,
    godMode=false,infStamina=false,
    autoEat=false,eatThreshold=40,autoHeal=false,healThreshold=40,autoRescue=false,
    fly=false,flySpeed=50,noclip=false,infJump=false,
    wsEnabled=false,walkspeed=50,jpEnabled=false,jumppower=120,antiAFK=false,
    gravityMod=false,gravityValue=100,
    espEnemy=false,espTree=false,espItem=false,espPlayer=false,espChest=false,
    espGem=false,espLog=false,espScrap=false,espFood=false,espFuel=false,espRescue=false,
    espTracer=false,espHealth=false,espName=false,
    espDist=true,espFill=0.6,espSize=13,
    fullbright=false,noFog=false,
    jitter=true,savedPos={},
    tpDuration=0.3,wsRampTime=0.8,breakRest=1,
    scanInterval=0.7,espInterval=0.15,flingInterval=0.1,remDedupe=0.15,
    locations={},
    autoWall=false,wallCount=8,wallRadius=12,wallDelay=3,
    autoRevive=false,reviveRange=20,
    autoDrop=false,dropTarget=nil,dropRange=15,
    autoPickup=false,pickupRange=10,
    scaleEnabled=false,scaleValue=1,
    crosshair=false,crosshairSize=8,crosshairColor=Color3.fromRGB(0,255,100),
    bypassCD=false,antiAFKPlus=false,
    autoSS=false,ssInterval=60,
}

local S = {
    run=true,con=nil,last={},cache={},hbRunning=false,
    scan={e={},t={},f={},i={},p={},c={},big={},g={},l={},s={},fd={},fu={},r={}},
    lastScan=0,esp={},tracers={},flyBV=nil,flyBG=nil,afk=nil,afkPlus=nil,
    count={k=0,c=0,f=0,b=0,items=0,chest=0,wall=0,revive=0,drop=0,pickup=0},
    loadTime=os.clock(),breakUntil=0,breakStart=0,
    wsTarget=nil,jpTarget=nil,tpRunning=false,
    spoofWS=16,spoofJP=50,origIndex=nil,origNamecall=nil,
    origGravity=196.2,lastEsp=0,lastFling=0,
    remLast={},scanCount=0,crosshairGui=nil,
}

local function jit(x) return C.jitter and x*(1+(math.random()*2-1)*0.25) or x end
local function chr() return plr.Character end
local function hrp() local c=chr() return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c=chr() return c and c:FindFirstChildOfClass("Humanoid") end
local function tls() local c=chr() return c and c:FindFirstChildOfClass("Tool") end
local function has(n,l) for _,k in ipairs(l) do if n:find(k) then return true end end end
local function isResting() return os.clock()<S.breakUntil end
local function startBreak() S.breakUntil=os.clock()+C.breakRest end
local function roll(p) return math.random()<p end
local function countTbl(t) local c=0 for _ in pairs(t) do c=c+1 end return c end

local hasHook = hookmetamethod and checkcaller and newcclosure
local hasConns = getconnections

local function enableSpoof()
    if not C.stealth or not C.spoofProps or not hasHook then return end
    if S.origIndex then return end
    local ok = pcall(function()
        local mt = getrawmetatable(game)
        S.origIndex = mt.__index
        S.origNamecall = mt.__namecall
        setreadonly(mt,false)
        mt.__index = newcclosure(function(self,key)
            if (key=="WalkSpeed" or key=="JumpPower") and not checkcaller() then
                local ok2, isHum = pcall(function() return self:IsA("Humanoid") end)
                if ok2 and isHum then
                    if key=="WalkSpeed" then return S.spoofWS end
                    if key=="JumpPower" then return S.spoofJP end
                end
            end
            return S.origIndex(self,key)
        end)
        mt.__namecall = newcclosure(function(self,...)
            local method = getnamecallmethod()
            if not checkcaller() and method=="Kick" then
                if self==plr then return end
            end
            return S.origNamecall(self,...)
        end)
        setreadonly(mt,true)
    end)
    if not ok then warn("[FT] Spoof failed") end
end

local function disableSpoof()
    if not S.origIndex then return end
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt,false)
        mt.__index = S.origIndex
        mt.__namecall = S.origNamecall
        setreadonly(mt,true)
    end)
    S.origIndex=nil S.origNamecall=nil
end

local function blockSuspicious()
    if not C.stealth or not C.blockRemotes or not hasConns then return end
    local kw = {"detect","report","flag","kick","ban","anticheat","ac_","guard"}
    for _,r in ipairs(RS:GetDescendants()) do
        if r:IsA("RemoteEvent") then
            local nm = r.Name:lower()
            for _,k in ipairs(kw) do
                if nm:find(k) then
                    pcall(function()
                        for _,c in ipairs(getconnections(r.OnClientEvent)) do
                            if c.Disable then c:Disable() end
                        end
                    end)
                    break
                end
            end
        end
    end
end

local K = {
    e={"deer","cult","wolf","bear","enemy","monster","raider","hunter","beast"},
    t={"tree","pine","oak","birch","log"},
    bt={"bigtree","big_tree","ancient","giant"},
    f={"fire","campfire","flame","torch","firepit"},
    c={"chest","crate","barrel","cache"},
    i={"item","drop","wood","scrap","fuel","food","stone","meat","berry","coin",
       "sapling","bandage","medicine","gold","flower"},
    gem={"gem","diamond","crystal","ruby","emerald","sapphire"},
    log={"log","wood","timber","plank"},
    scrap={"scrap","shred"},
    food={"food","meat","berry","fish","apple","bread","cooked"},
    fuel={"fuel","wood","coal","biofuel","gasoline"},
    flower={"flower","rose","tulip","daisy"},
    gold={"gold","coin","money"},
    rescue={"child","kid","victim","survivor","npc_rescue"},
    pick={"pickup","take","collect","loot","grab","interact","harvest","get"},
    atk={"attack","hit","damage","swing","melee","combat","stun"},
    fuelAdd={"addwood","feedfire","addfuel","wood","fuel","refuel"},
    plant={"plant","sapling","grow","seed","place"},
    heal={"heal","medkit","medicine","revive"},
    eat={"eat","consume","food","hunger"},
    scrapAct={"scrap","shred","recycle"},comp={"compress","press"},
    craft={"craft","build"},rescueAct={"rescue","save","free","unlock","kid"},
    wall={"wall","plank","fence","build","barricade"},
}

local function scan(f)
    local n=os.clock()
    if not f and n-S.lastScan<C.scanInterval then return S.scan end
    S.lastScan=n
    local h=hrp() if not h then return S.scan end
    local mp=h.Position
    local maxR=math.max(C.killRange,C.chopRange,C.fireRange,C.bringRange,300)
    local o={e={},t={},f={},i={},p={},c={},big={},g={},l={},s={},fd={},fu={},r={}}
    local count=0
    local myChar=chr()
    for _,v in ipairs(W:GetDescendants()) do
        local cls=v.ClassName
        if cls=="Model" then
            if v~=myChar then
                local r=v:FindFirstChild("HumanoidRootPart") or v.PrimaryPart
                if r then
                    local d=(r.Position-mp).Magnitude
                    if d<=maxR then
                        count=count+1
                        local nm=v.Name:lower()
                        local hh=v:FindFirstChildOfClass("Humanoid")
                        if hh and hh.Health>0 and has(nm,K.e) then o.e[#o.e+1]={m=v,r=r,d=d}
                        elseif has(nm,K.bt) or (has(nm,K.t) and r.Size.Y>15) then o.big[#o.big+1]={m=v,r=r,d=d}
                        elseif has(nm,K.t) then o.t[#o.t+1]={m=v,r=r,d=d}
                        elseif has(nm,K.f) then o.f[#o.f+1]={m=v,r=r,d=d}
                        elseif has(nm,K.c) then o.c[#o.c+1]={m=v,r=r,d=d}
                        elseif has(nm,K.rescue) then o.r[#o.r+1]={m=v,r=r,d=d} end
                    end
                end
            end
        elseif cls=="Part" or cls=="MeshPart" or cls=="UnionOperation"
            or cls=="TrussPart" or cls=="WedgePart" or cls=="CornerWedgePart" then
            local d=(v.Position-mp).Magnitude
            if d<=maxR then
                count=count+1
                local nm=v.Name:lower()
                if has(nm,K.f) then o.f[#o.f+1]={m=v,r=v,d=d}
                elseif has(nm,K.c) then o.c[#o.c+1]={m=v,r=v,d=d}
                elseif has(nm,K.gem) then o.g[#o.g+1]={p=v,d=d}
                elseif has(nm,K.scrap) then o.s[#o.s+1]={p=v,d=d}
                elseif has(nm,K.log) then o.l[#o.l+1]={p=v,d=d}
                elseif has(nm,K.fuel) and not has(nm,K.f) then o.fu[#o.fu+1]={p=v,d=d}
                elseif has(nm,K.food) then o.fd[#o.fd+1]={p=v,d=d}
                elseif has(nm,K.rescue) then o.r[#o.r+1]={p=v,d=d}
                elseif v:FindFirstChildOfClass("ProximityPrompt") or has(nm,K.i) then
                    o.i[#o.i+1]={p=v,d=d}
                end
            end
        end
    end
    for _,pl in ipairs(P:GetPlayers()) do
        if pl~=plr and pl.Character then
            local r=pl.Character:FindFirstChild("HumanoidRootPart")
            if r then local d=(r.Position-mp).Magnitude
                if d<=maxR then o.p[#o.p+1]={m=pl.Character,r=r,d=d,pl=pl} end
            end
        end
    end
    for _,x in pairs(o) do
        if #x>1 then table.sort(x,function(a,b) return a.d<b.d end) end
    end
    S.scan=o S.scanCount=count
    return o
end

local function rem(names,...)
    local key=table.concat(names,"|")
    local n=os.clock()
    if S.remLast[key] and (n-S.remLast[key])<C.remDedupe then return false end
    local a={...}
    if not S.cache[key] or #S.cache[key]==0 then
        S.cache[key]={}
        for _,r in ipairs(RS:GetDescendants()) do
            if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
                local nm=r.Name:lower()
                for _,n2 in ipairs(names) do
                    if nm:find(n2) then S.cache[key][#S.cache[key]+1]=r break end
                end
            end
        end
    end
    local hit=false
    for _,r in ipairs(S.cache[key]) do
        pcall(function()
            if r:IsA("RemoteEvent") then r:FireServer(unpack(a))
            else r:InvokeServer(unpack(a)) end
            hit=true
        end)
    end
    if hit then S.remLast[key]=n end
    return hit
end

local function prm(o)
    if not o then return false end
    for _,d in ipairs(o:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            if fireproximityprompt and pcall(fireproximityprompt,d,d.HoldDuration or 0) then return true end
            pcall(function() d:InputHoldBegin() task.wait(math.min(d.HoldDuration or 0,0.1)) d:InputHoldEnd() end)
            return true
        end
    end
    return false
end

local function atk()
    local t=tls() if t and t.Enabled and pcall(function() t:Activate() end) then return true end
    return false
end

local function face(p)
    local h=hrp() if not h then return end
    local d=p-h.Position
    pcall(function() h.CFrame=CFrame.lookAt(h.Position,h.Position+Vector3.new(d.X,0,d.Z)) end)
end

local function bring(x,h)
    local o=x.p or x.m
    if not o or not o.Parent then return end
    if o:IsA("BasePart") then
        if prm(o) then return end
        if o.Parent~=W and prm(o.Parent) then return end
        if rem(K.pick,o) then return end
        if o.Parent~=W then rem(K.pick,o.Parent) end
        if o.Anchored then return end
        pcall(function() o:SetNetworkOwner(plr) end)
        pcall(function()
            local d=h.Position-o.Position
            if d.Magnitude>1 then o.AssemblyLinearVelocity=d.Unit*C.bringSpeed end
        end)
    elseif o:IsA("Model") then
        pcall(function() o:PivotTo(h.CFrame*CFrame.new(0,0,-3)) end)
    end
end

local function useTool(kw)
    local bp=plr:FindFirstChildOfClass("Backpack") if not bp then return end
    for _,t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") and has(t.Name:lower(),kw) then
            t.Parent=chr()
            task.spawn(function()
                task.wait(0.05)
                pcall(function() t:Activate() end)
            end)
            return
        end
    end
end

local function tpModel(x,cf)
    if not cf or not x or not x.m then return end
    local obj=x.m
    if not obj.Parent then return end
    if obj:IsA("Model") then pcall(function() obj:PivotTo(cf) end)
    elseif obj:IsA("BasePart") then pcall(function() obj.CFrame=cf end) end
end

local function safeTP(cf)
    if S.tpRunning then return end
    local h=hrp() if not h then return end
    if not C.stealth or not C.safeTP or C.tpDuration<=0 then
        pcall(function() h.CFrame=cf end) return
    end
    S.tpRunning=true
    local done=false
    local ok=pcall(function()
        local t=TS:Create(h,TweenInfo.new(C.tpDuration,Enum.EasingStyle.Sine),{CFrame=cf})
        t:Play()
        t.Completed:Connect(function() done=true end)
    end)
    if not ok then S.tpRunning=false return end
    local timeout=os.clock()+C.tpDuration*3+0.5
    while not done and os.clock()<timeout do
        if not h.Parent then break end
        task.wait(0.05)
    end
    S.tpRunning=false
end

local function tp(t)
    local h=hrp() if not h then return end
    local target
    if type(t)=="userdata" and t:IsA("Player") and t.Character then
        local r=t.Character:FindFirstChild("HumanoidRootPart")
        if r then target=r.CFrame+Vector3.new(0,3,0) end
    elseif typeof(t)=="Vector3" then target=CFrame.new(t)
    elseif typeof(t)=="CFrame" then target=t
    elseif type(t)=="table" and t.r then target=t.r.CFrame+Vector3.new(0,3,0) end
    if not target then return end
    safeTP(target)
end

local function rampSpeed(target)
    local h=hum() if not h then return end
    if S.wsTarget==target then return end
    S.wsTarget=target
    local start=h.WalkSpeed
    task.spawn(function()
        for i=1,25 do
            if not S.run or not hum() then break end
            if S.wsTarget~=target then break end
            local a=i/25
            local v=start+(target-start)*a
            h.WalkSpeed=v S.spoofWS=v
            task.wait(C.wsRampTime/25)
        end
        if C.stealth then S.spoofWS=C.wsEnabled and C.walkspeed or 16 end
    end)
end

local function rampJump(target)
    local h=hum() if not h or not h.UseJumpPower then return end
    if S.jpTarget==target then return end
    S.jpTarget=target
    local start=h.JumpPower
    task.spawn(function()
        for i=1,20 do
            if not S.run or not hum() then break end
            if S.jpTarget~=target then break end
            local a=i/20
            local v=start+(target-start)*a
            h.JumpPower=v S.spoofJP=v
            task.wait(C.wsRampTime/20)
        end
        if C.stealth then S.spoofJP=C.jpEnabled and C.jumppower or 50 end
    end)
end

local function clearESP()
    for _,g in pairs(S.esp) do
        if g.box then pcall(function() g.box:Destroy() end) end
        if g.lbl then pcall(function() g.lbl:Destroy() end) end
    end
    S.esp={} S.tracers={}
end

local function draw(o,col,d,extra)
    if not S.esp[o] then
        local b=Instance.new("BoxHandleAdornment")
        b.Size=Vector3.new(3,5,3) b.AlwaysOnTop=true b.ZIndex=5
        b.Transparency=C.espFill b.Adornee=o b.Color3=col b.Parent=CG
        local l=Instance.new("BillboardGui")
        l.Size=UDim2.new(0,140,0,40) l.StudsOffset=Vector3.new(0,3.5,0)
        l.AlwaysOnTop=true l.Adornee=o l.Parent=CG
        local t=Instance.new("TextLabel",l)
        t.Size=UDim2.new(1,0,1,0) t.BackgroundTransparency=1
        t.TextColor3=col t.TextStrokeTransparency=0
        t.Font=Enum.Font.GothamBold t.TextSize=C.espSize
        S.esp[o]={box=b,lbl=l,txt=t}
    end
    local g=S.esp[o]
    if g.txt then
        local parts={}
        if C.espName then parts[#parts+1]=o.Name end
        if C.espDist then parts[#parts+1]=("["..math.floor(d).."m]") end
        if C.espHealth and extra then parts[#parts+1]=extra end
        g.txt.Text=table.concat(parts," ")
    end
end

local function espLoop()
    if not (C.espPlayer or C.espEnemy or C.espItem or C.espTree or C.espChest
            or C.espGem or C.espLog or C.espScrap or C.espFood or C.espFuel or C.espRescue) then
        return
    end
    local n=os.clock()
    if n-S.lastEsp<C.espInterval then return end
    S.lastEsp=n
    local d=scan() local seen={}
    local function process(list,col,getHealth)
        for _,x in ipairs(list) do
            local obj=x.m or x.p
            if obj then
                seen[obj]=true
                local extra=nil
                if getHealth and x.m then
                    local hh=x.m:FindFirstChildOfClass("Humanoid")
                    if hh then extra=math.floor(hh.Health).."/"..math.floor(hh.MaxHealth) end
                end
                draw(obj,col,x.d,extra)
            end
        end
    end
    if C.espEnemy then process(d.e,Color3.new(1,.2,.2),true) end
    if C.espTree then process(d.t,Color3.new(.2,1,.2)) end
    if C.espTree then process(d.big,Color3.new(0,1,.8)) end
    if C.espItem then process(d.i,Color3.new(1,1,.2)) end
    if C.espChest then process(d.c,Color3.new(1,.6,0)) end
    if C.espPlayer then process(d.p,Color3.new(.3,.7,1),true) end
    if C.espGem then process(d.g,Color3.new(.9,.3,1)) end
    if C.espLog then process(d.l,Color3.new(.6,.4,.2)) end
    if C.espScrap then process(d.s,Color3.new(.7,.7,.7)) end
    if C.espFood then process(d.fd,Color3.new(1,.8,.3)) end
    if C.espFuel then process(d.fu,Color3.new(1,.5,0)) end
    if C.espRescue then process(d.r,Color3.new(.5,1,.5)) end
    for o,g in pairs(S.esp) do
        if not seen[o] or not o.Parent then
            if g.box then pcall(function() g.box:Destroy() end) end
            if g.lbl then pcall(function() g.lbl:Destroy() end) end
            S.esp[o]=nil
        end
    end
end

local function setFly(v)
    local h=hrp() if not h then return end
    if v then
        if S.flyBV and S.flyBV.Parent==h then return end
        if S.flyBV then S.flyBV:Destroy() end
        if S.flyBG then S.flyBG:Destroy() end
        S.flyBV=Instance.new("BodyVelocity",h)
        S.flyBV.MaxForce=Vector3.new(1e5,1e5,1e5) S.flyBV.Velocity=Vector3.zero
        S.flyBG=Instance.new("BodyGyro",h)
        S.flyBG.MaxTorque=Vector3.new(1e5,1e5,1e5) S.flyBG.P=1000
    else
        if S.flyBV then S.flyBV:Destroy() S.flyBV=nil end
        if S.flyBG then S.flyBG:Destroy() S.flyBG=nil end
    end
end

local function flyStep()
    if not C.fly then return end
    local h=hrp() if not h then return end
    if not S.flyBV or S.flyBV.Parent~=h then setFly(true) return end
    local cam=W.CurrentCamera if not cam then return end
    local dir=Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector*-1 end
    if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.yAxis end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir=dir-Vector3.yAxis end
    local target=dir.Magnitude>0 and dir.Unit*C.flySpeed or Vector3.zero
    S.flyBV.Velocity=S.flyBV.Velocity:Lerp(target,0.3)
    S.flyBG.CFrame=cam.CFrame
end

local function noclipStep()
    if not C.noclip then return end
    local c=chr() if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end
    end
end

local function antiFlingStep()
    if not C.antiFling then return end
    local n=os.clock()
    if n-S.lastFling<C.flingInterval then return end
    S.lastFling=n
    local c=chr() if not c then return end
    local h=c:FindFirstChild("HumanoidRootPart")
    if not h then return end
    for _,v in ipairs(h:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyAngularVelocity")
           or v:IsA("BodyForce") or v:IsA("BodyThrust") then
            if v~=S.flyBV then v:Destroy() end
        end
    end
    local overlap=W:GetPartBoundsInRadius(h.Position,5,OverlapParams.new())
    for _,part in ipairs(overlap) do
        local other=part:FindFirstAncestorOfClass("Model")
        if other and other~=c and P:GetPlayerFromCharacter(other) then
            h.CFrame=h.CFrame+Vector3.new(0,2,0)
            break
        end
    end
end

local function setGravity(v)
    if v then S.origGravity=W.Gravity W.Gravity=C.gravityValue
    else W.Gravity=S.origGravity end
end

local function setAFK(v)
    local VU=game:GetService("VirtualUser")
    if v and not S.afk then
        S.afk=R.Heartbeat:Connect(function()
            pcall(function() VU:CaptureController() VU:ClickButton2(Vector2.new()) end)
        end)
    elseif not v and S.afk then S.afk:Disconnect() S.afk=nil end
end

local function setAFKPlus(v)
    if v and not S.afkPlus then
        S.afkPlus=R.Heartbeat:Connect(function()
            local h=hum()
            if h then
                pcall(function()
                    if math.random()<0.02 then
                        h:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end)
            end
            local cam=W.CurrentCamera
            if cam and math.random()<0.01 then
                pcall(function()
                    cam.CFrame=cam.CFrame*CFrame.Angles(0,math.rad(math.random(-5,5)),0)
                end)
            end
        end)
    elseif not v and S.afkPlus then
        S.afkPlus:Disconnect() S.afkPlus=nil
    end
end

local function autoWallStep()
    if not C.autoWall then return end
    local n=os.clock()
    if n-(S.last.wall or 0)<jit(C.wallDelay) then return end
    S.last.wall=n
    local h=hrp() if not h then return end
    local bp=plr:FindFirstChildOfClass("Backpack") if not bp then return end
    for _,t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") and has(t.Name:lower(),K.wall) then
            t.Parent=chr()
            S.count.wall=S.count.wall+1
            task.spawn(function()
                for i=1,C.wallCount do
                    local a=(i/C.wallCount)*math.pi*2
                    local pos=h.Position+Vector3.new(math.cos(a)*C.wallRadius,0,math.sin(a)*C.wallRadius)
                    face(pos)
                    pcall(function() t:Activate() end)
                    task.wait(0.08)
                end
            end)
            break
        end
    end
end

local function autoReviveStep()
    if not C.autoRevive then return end
    local n=os.clock()
    if n-(S.last.revive or 0)<jit(1.5) then return end
    S.last.revive=n
    local h=hrp() if not h then return end
    local d=scan()
    for _,x in ipairs(d.p) do
        local hh=x.m:FindFirstChildOfClass("Humanoid")
        if hh and hh.Health<hh.MaxHealth and x.d<=C.reviveRange then
            face(x.r.Position)
            useTool(K.heal)
            rem({"revive","heal","respawn","reviveplayer"},x.pl)
            S.count.revive=S.count.revive+1
            break
        end
    end
end

local function autoDropStep()
    if not C.autoDrop or not C.dropTarget then return end
    local n=os.clock()
    if n-(S.last.drop or 0)<jit(2) then return end
    S.last.drop=n
    local t=C.dropTarget
    if type(t)~="userdata" or not t.Character then return end
    local tr=t.Character:FindFirstChild("HumanoidRootPart")
    local h=hrp()
    if not tr or not h then return end
    if (tr.Position-h.Position).Magnitude>C.dropRange then return end
    face(tr.Position)
    local bp=plr:FindFirstChildOfClass("Backpack") if not bp then return end
    for _,tool in ipairs(bp:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Parent=chr()
            S.count.drop=S.count.drop+1
            task.spawn(function()
                task.wait(0.05)
                rem({"drop","toss","give","place"},tr.CFrame)
                task.wait(0.2)
                pcall(function() if tool.Parent~=bp then tool.Parent=bp end end)
            end)
            break
        end
    end
end

local function autoPickupStep()
    if not C.autoPickup then return end
    local n=os.clock()
    if n-(S.last.pickN or 0)<jit(0.3) then return end
    S.last.pickN=n
    local h=hrp() if not h then return end
    local d=scan()
    for _,x in ipairs(d.i) do
        if x.d<=C.pickupRange then
            bring(x,h)
            S.count.pickup=S.count.pickup+1
        end
    end
end

local function setScale(v)
    local c=chr() if not c then return end
    local h=c:FindFirstChildOfClass("Humanoid")
    if not h then return end
    for _,attr in ipairs({"Scale","BodyScale","BodyDepthScale","BodyWidthScale","HeadScale"}) do
        pcall(function() h:SetAttribute(attr,v) end)
    end
end

local function scaleStep()
    if not C.scaleEnabled then return end
    local c=chr() if not c then return end
    local h=c:FindFirstChildOfClass("Humanoid")
    if not h then return end
    local cur=h:GetAttribute("Scale") or h:GetAttribute("BodyScale") or 1
    if math.abs(cur-C.scaleValue)>0.05 then setScale(C.scaleValue) end
end

local function setCrosshair(v)
    if v then
        if S.crosshairGui and S.crosshairGui.Parent then return end
        local g=Instance.new("ScreenGui")
        g.Name="FT_Cross_"..tick()
        g.ResetOnSpawn=false
        g.IgnoreGuiInset=true
        g.DisplayOrder=999
        pcall(function() g.Parent=CG end)
        if not g.Parent then g.Parent=plr:WaitForChild("PlayerGui") end
        local hz=Instance.new("Frame",g)
        hz.Size=UDim2.new(0,C.crosshairSize*2,0,2)
        hz.Position=UDim2.new(0.5,-C.crosshairSize,0.5,-1)
        hz.BackgroundColor3=C.crosshairColor
        hz.BorderSizePixel=0
        local vt=Instance.new("Frame",g)
        vt.Size=UDim2.new(0,2,0,C.crosshairSize*2)
        vt.Position=UDim2.new(0.5,-1,0.5,-C.crosshairSize)
        vt.BackgroundColor3=C.crosshairColor
        vt.BorderSizePixel=0
        local dot=Instance.new("Frame",g)
        dot.Size=UDim2.new(0,2,0,2)
        dot.Position=UDim2.new(0.5,-1,0.5,-1)
        dot.BackgroundColor3=C.crosshairColor
        dot.BorderSizePixel=0
        S.crosshairGui=g
    else
        if S.crosshairGui then
            pcall(function() S.crosshairGui:Destroy() end)
            S.crosshairGui=nil
        end
    end
end

local function bypassCDStep()
    if not C.bypassCD then return end
    local t=tls() if not t then return end
    pcall(function()
        for _,attr in ipairs({"Cooldown","cooldown","cd","LastUsed","SwingCD","AttackCD"}) do
            if t:GetAttribute(attr) then t:SetAttribute(attr,0) end
        end
    end)
end

local function autoSSStep()
    if not C.autoSS then return end
    local n=os.clock()
    if n-(S.last.ss or 0)<C.ssInterval then return end
    S.last.ss=n
    pcall(function()
        if screenshot then screenshot("FT_"..os.time()..".png")
        elseif saveScreenshot then saveScreenshot("FT_"..os.time()..".png") end
    end)
end

UIS.JumpRequest:Connect(function()
    if C.infJump then local h=hum() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

plr.CharacterAdded:Connect(function()
    task.wait(1)
    if C.fly then S.flyBV=nil S.flyBG=nil setFly(true) end
    S.wsTarget=nil S.jpTarget=nil
    S.spoofWS=C.wsEnabled and C.walkspeed or 16
    S.spoofJP=C.jpEnabled and C.jumppower or 50
    if C.scaleEnabled then setScale(C.scaleValue) end
end)

local function hb()
    if not S.run or S.hbRunning then return end
    S.hbRunning=true
    local ok,err=pcall(function()
        local n,h,hm=os.clock(),hrp(),hum()
        if not h or not hm or hm.Health<=0 then
            if S.tpRunning then S.tpRunning=false end
            return
        end
        local d=scan()

        if C.killAura and #d.e>0 and n-(S.last.k or 0)>=jit(C.killDelay) and not isResting() then
            local t=d.e[1]
            if t.d<=C.killRange then
                if not (C.stealth and roll(C.killMiss)) then
                    if C.aimAssist and W.CurrentCamera then
                        pcall(function()
                            W.CurrentCamera.CFrame=CFrame.lookAt(W.CurrentCamera.CFrame.Position,t.r.Position)
                        end)
                    end
                    face(t.r.Position)
                    if not atk() then rem(K.atk,t.m) end
                    S.count.k=S.count.k+1
                end
                S.last.k=n
                if C.stealth and (n-S.breakStart)>C.killBreak then
                    S.breakStart=n startBreak()
                end
            end
        end

        if C.chopAura and n-(S.last.c or 0)>=jit(C.chopDelay) and not isResting() then
            local t=(C.chopBig and #d.big>0) and d.big[1] or (#d.t>0 and d.t[1] or nil)
            if t and t.d<=C.chopRange then
                if not (C.stealth and roll(C.chopMiss)) then
                    face(t.r.Position)
                    if not atk() then prm(t.m) end
                    S.count.c=S.count.c+1
                end
                S.last.c=n
                if C.stealth and (n-S.breakStart)>C.chopBreak then
                    S.breakStart=n startBreak()
                end
            end
        end

        if C.stun and #d.e>0 and n-(S.last.st or 0)>=jit(1.2) then
            local t=d.e[1]
            if t.d<=C.stunRange then face(t.r.Position) atk() S.last.st=n end
        end

        if C.entityGod then
            for _,x in ipairs(d.e) do
                local hh=x.m:FindFirstChildOfClass("Humanoid")
                if hh then pcall(function() hh.Health=hh.MaxHealth end) end
            end
        end

        if C.autoFire and #d.f>0 and n-(S.last.f or 0)>=jit(C.fireDelay) then
            local t=d.f[1]
            if t.d<=C.fireRange then
                if not prm(t.m) then rem(K.fuelAdd,t.m) end
                S.last.f=n S.count.f=S.count.f+1
            end
        end

        if C.autoCook and #d.f>0 and n-(S.last.cook or 0)>=jit(2.5) then
            for _,f in ipairs(d.f) do
                if f.d<=30 then useTool(K.eat) break end
            end
            S.last.cook=n
        end

        if C.bringItem and #d.i>0 and n-(S.last.b or 0)>=jit(C.bringDelay) and not isResting() then
            if C.bringAll then
                local cnt=0
                for _,x in ipairs(d.i) do
                    if x.d<=C.bringRange then bring(x,h) cnt=cnt+1 if cnt>=5 then break end end
                end
                S.count.items=S.count.items+cnt
            else
                for _,x in ipairs(d.i) do
                    if x.d<=C.bringRange then
                        if C.bringFilter=="all" or x.p.Name:lower():find(C.bringFilter) then
                            bring(x,h) S.count.b=S.count.b+1 break
                        end
                    end
                end
            end
            S.last.b=n
        end

        if C.autoOpenChest and #d.c>0 and n-(S.last.chest or 0)>=jit(0.5) then
            for _,x in ipairs(d.c) do
                if x.d<=C.chestRange then
                    if x.p then prm(x.p) else prm(x.m) end
                    S.count.chest=S.count.chest+1
                end
            end
            S.last.chest=n
        end

        if C.autoCollect and n-(S.last.pick or 0)>=jit(0.4) then
            for _,x in ipairs(d.i) do
                if x.d<=C.bringRange then
                    local nm=x.p.Name:lower()
                    if (C.collectFlowers and has(nm,K.flower)) or (C.collectGold and has(nm,K.gold)) then
                        prm(x.p)
                    end
                end
            end
            S.last.pick=n
        end

        if C.autoEat and n-(S.last.eat or 0)>=jit(2) then
            local hunger=100
            for _,obj in ipairs({hm,chr(),plr}) do
                if obj then
                    local v=obj:GetAttribute("Hunger") or obj:GetAttribute("Food") or obj:GetAttribute("Thirst")
                    if v then hunger=v break end
                end
            end
            if hunger<C.eatThreshold then useTool(K.eat) end
            S.last.eat=n
        end

        if C.autoHeal and hm.Health<C.healThreshold and n-(S.last.heal or 0)>=jit(2.5) then
            useTool(K.heal) rem(K.heal) S.last.heal=n
        end

        if C.autoRescue and n-(S.last.resc or 0)>=jit(3.5) then
            for _,x in ipairs(d.r) do
                if x.d<=200 then
                    if x.p then prm(x.p) else prm(x.m) end
                end
            end
            for _,x in ipairs(d.i) do
                local nm=x.p.Name:lower()
                if x.d<=200 and (has(nm,K.rescueAct) or nm:find("child") or nm:find("kid")) then
                    prm(x.p) break
                end
            end
            rem(K.rescueAct) S.last.resc=n
        end

        if C.autoPlant and n-(S.last.plant or 0)>=jit(2.5) then
            for i=1,C.plantCount do
                local a=(i/C.plantCount)*math.pi*2
                local pos=h.Position+Vector3.new(math.cos(a)*15,0,math.sin(a)*15)
                rem(K.plant,CFrame.new(pos))
            end
            S.last.plant=n
        end
        if C.autoScrap then rem(K.scrapAct) end
        if C.autoCompress then rem(K.comp) end
        if C.autoCraft then rem(K.craft) end

        autoWallStep() autoReviveStep() autoDropStep() autoPickupStep()
        scaleStep() bypassCDStep() autoSSStep()

        if C.wsEnabled then
            local target=C.stealth and math.min(C.walkspeed,50) or C.walkspeed
            if math.abs(hm.WalkSpeed-target)>0.5 then rampSpeed(target) end
        end
        if C.jpEnabled and hm.UseJumpPower then
            local target=C.stealth and math.min(C.jumppower,120) or C.jumppower
            if math.abs(hm.JumpPower-target)>0.5 then rampJump(target) end
        end

        if C.godMode and hm.Health<hm.MaxHealth then pcall(function() hm.Health=hm.MaxHealth end) end
        if C.infStamina then
            pcall(function()
                for _,a in ipairs({"Stamina","Energy","Hunger","Thirst"}) do
                    if hm:GetAttribute(a) then hm:SetAttribute(a,100) end
                end
            end)
        end
        flyStep() noclipStep() antiFlingStep() espLoop()

        if C.fullbright then
            LG.Brightness=3 LG.ClockTime=14 LG.Ambient=Color3.fromRGB(200,200,200)
        end
        if C.noFog then LG.FogEnd=1e6 LG.FogStart=1e6 end
    end)
    S.hbRunning=false
    if not ok then warn("[FT hb]",tostring(err)) end
end

local function ui()
    local g=Instance.new("ScreenGui")
    g.Name="FT_"..tick() g.ResetOnSpawn=false g.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    pcall(function() g.Parent=CG end) if not g.Parent then g.Parent=plr:WaitForChild("PlayerGui") end

    local m=Instance.new("Frame",g)
    m.Size=UDim2.new(0,640,0,440) m.Position=UDim2.new(.5,-320,.5,-220)
    m.BackgroundColor3=Color3.fromRGB(22,24,30) m.BorderSizePixel=0 m.Active=true m.Draggable=true
    Instance.new("UICorner",m).CornerRadius=UDim.new(0,10)

    local tb=Instance.new("Frame",m)
    tb.Size=UDim2.new(1,0,0,32) tb.BackgroundColor3=Color3.fromRGB(32,34,42) tb.BorderSizePixel=0
    Instance.new("UICorner",tb).CornerRadius=UDim.new(0,10)
    local tl=Instance.new("TextLabel",tb)
    tl.Size=UDim2.new(1,-40,1,0) tl.Position=UDim2.new(0,12,0,0)
    tl.BackgroundTransparency=1 tl.Text="🌲 FOREST TOOLKIT v3.4.3"
    tl.TextColor3=Color3.fromRGB(200,240,210) tl.Font=Enum.Font.GothamBold tl.TextSize=13
    tl.TextXAlignment=Enum.TextXAlignment.Left
    local cl=Instance.new("TextButton",tb)
    cl.Size=UDim2.new(0,32,0,32) cl.Position=UDim2.new(1,-32,0,0)
    cl.BackgroundTransparency=1 cl.Text="✕" cl.TextColor3=Color3.fromRGB(255,110,110)
    cl.Font=Enum.Font.GothamBold cl.TextSize=16
    cl.MouseButton1Click:Connect(function() g:Destroy() end)

    local tabs={"Combat","Items","Bring","Survival","TP","Visuals","Misc"}
    local tbar=Instance.new("Frame",m)
    tbar.Size=UDim2.new(0,110,1,-32) tbar.Position=UDim2.new(0,0,0,32)
    tbar.BackgroundColor3=Color3.fromRGB(28,30,38) tbar.BorderSizePixel=0
    local ct=Instance.new("Frame",m)
    ct.Size=UDim2.new(1,-110,1,-32) ct.Position=UDim2.new(0,110,0,32)
    ct.BackgroundColor3=Color3.fromRGB(22,24,30) ct.BorderSizePixel=0

    local pages={}
    for i,nm in ipairs(tabs) do
        local b=Instance.new("TextButton",tbar)
        b.Size=UDim2.new(1,0,0,30) b.Position=UDim2.new(0,0,0,(i-1)*30)
        b.BackgroundColor3=Color3.fromRGB(28,30,38) b.BorderSizePixel=0
        b.Text="  "..nm b.TextColor3=Color3.fromRGB(180,180,190)
        b.Font=Enum.Font.Gotham b.TextSize=12 b.TextXAlignment=Enum.TextXAlignment.Left
        local p=Instance.new("ScrollingFrame",ct)
        p.Size=UDim2.new(1,0,1,0) p.BackgroundTransparency=1 p.BorderSizePixel=0
        p.CanvasSize=UDim2.new(0,0,0,0) p.AutomaticCanvasSize=Enum.AutomaticSize.Y
        p.ScrollBarThickness=4 p.Visible=(i==1) pages[nm]=p
        b.MouseButton1Click:Connect(function()
            for _,pg in pairs(pages) do pg.Visible=false end
            p.Visible=true
            for _,bb in ipairs(tbar:GetChildren()) do
                if bb:IsA("TextButton") then bb.TextColor3=Color3.fromRGB(180,180,190) end
            end
            b.TextColor3=Color3.fromRGB(120,220,150)
        end)
    end

    local pageY={}
    for _,nm in ipairs(tabs) do pageY[nm]=0 end
    local function nextY(pg,h)
        local y=pageY[pg] pageY[pg]=y+h return y
    end

    local function tog(pg,lb,key,cb)
        local r=Instance.new("Frame",pages[pg])
        r.Size=UDim2.new(1,-16,0,28) r.Position=UDim2.new(0,8,0,nextY(pg,30))
        r.BackgroundTransparency=1
        local l=Instance.new("TextLabel",r)
        l.Size=UDim2.new(.75,0,1,0) l.BackgroundTransparency=1 l.Text=lb
        l.TextColor3=Color3.fromRGB(215,215,225) l.Font=Enum.Font.Gotham
        l.TextSize=12 l.TextXAlignment=Enum.TextXAlignment.Left
        local b=Instance.new("TextButton",r)
        b.Size=UDim2.new(0,42,0,19) b.Position=UDim2.new(1,-42,.5,-9.5)
        b.BackgroundColor3=C[key] and Color3.fromRGB(90,200,120) or Color3.fromRGB(55,58,70)
        b.Text=C[key] and "ON" or "OFF" b.TextColor3=Color3.fromRGB(255,255,255)
        b.Font=Enum.Font.GothamBold b.TextSize=10 b.BorderSizePixel=0
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
        b.MouseButton1Click:Connect(function()
            C[key]=not C[key]
            b.BackgroundColor3=C[key] and Color3.fromRGB(90,200,120) or Color3.fromRGB(55,58,70)
            b.Text=C[key] and "ON" or "OFF"
            if cb then cb(C[key]) end
        end)
    end

    local function sld(pg,lb,key,mn,mx)
        local r=Instance.new("Frame",pages[pg])
        r.Size=UDim2.new(1,-16,0,42) r.Position=UDim2.new(0,8,0,nextY(pg,44))
        r.BackgroundTransparency=1
        local l=Instance.new("TextLabel",r)
        l.Size=UDim2.new(1,0,0,18) l.BackgroundTransparency=1
        l.Text=lb..": "..tostring(C[key]) l.TextColor3=Color3.fromRGB(215,215,225)
        l.Font=Enum.Font.Gotham l.TextSize=11 l.TextXAlignment=Enum.TextXAlignment.Left
        local br=Instance.new("Frame",r)
        br.Size=UDim2.new(1,0,0,6) br.Position=UDim2.new(0,0,0,26)
        br.BackgroundColor3=Color3.fromRGB(50,52,62) br.BorderSizePixel=0
        Instance.new("UICorner",br).CornerRadius=UDim.new(0,3)
        local f=Instance.new("Frame",br)
        f.Size=UDim2.new((C[key]-mn)/(mx-mn),0,1,0)
        f.BackgroundColor3=Color3.fromRGB(90,200,120) f.BorderSizePixel=0
        Instance.new("UICorner",f).CornerRadius=UDim.new(0,3)
        local dr=false
        local function upd(x)
            local rel=math.clamp((x-br.AbsolutePosition.X)/br.AbsoluteSize.X,0,1)
            local v=mn+(mx-mn)*rel
            if (mx-mn)>10 then v=math.floor(v) end
            C[key]=v f.Size=UDim2.new(rel,0,1,0) l.Text=lb..": "..v
        end
        br.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true upd(i.Position.X) end
        end)
        UIS.InputChanged:Connect(function(i)
            if dr and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false end
        end)
    end

    local function btn(pg,lb,cb)
        local b=Instance.new("TextButton",pages[pg])
        b.Size=UDim2.new(1,-16,0,28) b.Position=UDim2.new(0,8,0,nextY(pg,30))
        b.BackgroundColor3=Color3.fromRGB(42,44,56) b.Text=lb
        b.TextColor3=Color3.fromRGB(220,220,230) b.Font=Enum.Font.Gotham
        b.TextSize=12 b.BorderSizePixel=0
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
        b.MouseButton1Click:Connect(cb)
    end

    local function sec(pg,lb)
        local l=Instance.new("TextLabel",pages[pg])
        l.Size=UDim2.new(1,-16,0,22) l.Position=UDim2.new(0,8,0,nextY(pg,24))
        l.BackgroundTransparency=1 l.Text="── "..lb.." ──"
        l.TextColor3=Color3.fromRGB(120,220,150) l.Font=Enum.Font.GothamBold l.TextSize=11
    end

    sec("Combat","🛡 STEALTH")
    tog("Combat","Stealth Mode","stealth")
    tog("Combat","Spoof Props","spoofProps")
    tog("Combat","Block Remotes","blockRemotes")
    tog("Combat","Safe TP","safeTP")
    sld("Combat","TP Duration","tpDuration",0,2)
    sld("Combat","Break Rest","breakRest",0.5,5)
    sec("Combat","ATTACK")
    tog("Combat","Kill Aura","killAura")
    sld("Combat","Kill Range","killRange",10,500)
    sld("Combat","Kill Delay","killDelay",0.2,2)
    sld("Combat","Kill Miss","killMiss",0,0.5)
    sld("Combat","Kill Break","killBreak",10,120)
    tog("Combat","Aim Assist","aimAssist")
    tog("Combat","Chop Aura","chopAura")
    sld("Combat","Chop Range","chopRange",10,500)
    sld("Combat","Chop Delay","chopDelay",0.2,2)
    sld("Combat","Chop Miss","chopMiss",0,0.5)
    sld("Combat","Chop Break","chopBreak",10,120)
    tog("Combat","Big Trees First","chopBig")
    sec("Combat","CONTROL")
    tog("Combat","Auto Stun","stun")
    sld("Combat","Stun Range","stunRange",5,100)
    tog("Combat","Entity Godmode","entityGod")
    tog("Combat","Anti-Fling","antiFling")

    sec("Items","AUTO FARM")
    tog("Items","Auto Collect","autoCollect")
    tog("Items","  ↳ Flowers","collectFlowers")
    tog("Items","  ↳ Gold","collectGold")
    tog("Items","Auto Fire","autoFire")
    sld("Items","Fire Range","fireRange",10,300)
    tog("Items","Auto Cook","autoCook")
    tog("Items","Auto Open Chest","autoOpenChest")
    sld("Items","Chest Range","chestRange",10,150)
    tog("Items","Auto Plant","autoPlant")
    sld("Items","Plant Count","plantCount",1,20)
    tog("Items","Auto Scrap","autoScrap")
    tog("Items","Auto Compress","autoCompress")
    tog("Items","Auto Craft","autoCraft")
    sec("Items","UTILITY")
    tog("Items","Auto Pickup Nearby","autoPickup")
    sld("Items","Pickup Range","pickupRange",5,50)
    tog("Items","Bypass Tool Cooldown","bypassCD")

    sec("Bring","SETTINGS")
    tog("Bring","Enable Bring","bringItem")
    sld("Bring","Range","bringRange",10,300)
    sld("Bring","Delay","bringDelay",0.3,3)
    sld("Bring","Speed","bringSpeed",10,60)
    tog("Bring","Bring ALL Mode","bringAll")
    sec("Bring","FILTER")
    btn("Bring","Filter: All",function() C.bringFilter="all" print("[FT] all") end)
    btn("Bring","Filter: Wood",function() C.bringFilter="wood" print("[FT] wood") end)
    btn("Bring","Filter: Food",function() C.bringFilter="food" print("[FT] food") end)
    btn("Bring","Filter: Fuel",function() C.bringFilter="fuel" print("[FT] fuel") end)
    btn("Bring","Filter: Scrap",function() C.bringFilter="scrap" print("[FT] scrap") end)
    btn("Bring","Filter: Gem",function() C.bringFilter="gem" print("[FT] gem") end)
    sec("Bring","QUICK BRING")
    btn("Bring","Bring All Items",function()
        local h=hrp() if not h then return end
        local d=scan()
        for _,x in ipairs(d.i) do if x.d<=C.bringRange then bring(x,h) end end
    end)
    btn("Bring","Bring All Gems",function()
        local h=hrp() if not h then return end
        local d=scan()
        for _,x in ipairs(d.g) do if x.d<=C.bringRange then bring(x,h) end end
    end)
    btn("Bring","Bring All Logs",function()
        local h=hrp() if not h then return end
        local d=scan()
        for _,x in ipairs(d.l) do if x.d<=C.bringRange then bring(x,h) end end
    end)
    btn("Bring","Bring All Scrap",function()
        local h=hrp() if not h then return end
        local d=scan()
        for _,x in ipairs(d.s) do if x.d<=C.bringRange then bring(x,h) end end
    end)
    btn("Bring","Bring All Food",function()
        local h=hrp() if not h then return end
        local d=scan()
        for _,x in ipairs(d.fd) do if x.d<=C.bringRange then bring(x,h) end end
    end)
    btn("Bring","Bring All Fuel",function()
        local h=hrp() if not h then return end
        local d=scan()
        for _,x in ipairs(d.fu) do if x.d<=C.bringRange then bring(x,h) end end
    end)
    btn("Bring","Bring All Chests",function()
        local h=hrp() if not h then return end
        local d=scan()
        for _,x in ipairs(d.c) do
            if x.d<=C.bringRange then
                if x.m then tpModel(x,h.CFrame*CFrame.new(0,0,-5))
                else bring(x,h) end
            end
        end
    end)
    btn("Bring","Bring All Enemies",function()
        local h=hrp() if not h then return end
        local d=scan()
        for _,x in ipairs(d.e) do
            if x.d<=C.bringRange then
                pcall(function() x.m:PivotTo(h.CFrame*CFrame.new(0,0,-8)) end)
            end
        end
    end)
    btn("Bring","Bring All Rescues",function()
        local h=hrp() if not h then return end
        local d=scan()
        for _,x in ipairs(d.r) do
            if x.d<=C.bringRange then
                if x.m then pcall(function() x.m:PivotTo(h.CFrame) end)
                else bring(x,h) end
            end
        end
    end)
    sec("Bring","DROP FOR TEAMMATE")
    tog("Bring","Auto Drop for Teammate","autoDrop")
    sld("Bring","Drop Range","dropRange",5,50)
    btn("Bring","Set Drop Target (nearest)",function()
        local d=scan()
        if #d.p>0 then
            C.dropTarget=d.p[1].pl
            print("[FT] Target: "..d.p[1].pl.Name)
        end
    end)

    sec("Survival","PROTECT")
    tog("Survival","God Mode","godMode")
    tog("Survival","Inf Stamina","infStamina")
    sec("Survival","CARE")
    tog("Survival","Auto Eat","autoEat")
    sld("Survival","Eat Threshold","eatThreshold",10,90)
    tog("Survival","Auto Heal","autoHeal")
    sld("Survival","Heal Threshold","healThreshold",10,90)
    tog("Survival","Auto Rescue","autoRescue")
    tog("Survival","Auto Revive Teammate","autoRevive")
    sld("Survival","Revive Range","reviveRange",5,50)
    sec("Survival","BUILD")
    tog("Survival","Auto Build Wall","autoWall")
    sld("Survival","Wall Count","wallCount",4,16)
    sld("Survival","Wall Radius","wallRadius",5,30)
    sld("Survival","Wall Delay","wallDelay",1,10)
    sec("Survival","MOVEMENT")
    tog("Survival","Fly","fly",setFly)
    sld("Survival","Fly Speed","flySpeed",10,100)
    tog("Survival","Noclip","noclip")
    tog("Survival","Inf Jump","infJump")
    tog("Survival","WalkSpeed+","wsEnabled")
    sld("Survival","WalkSpeed","walkspeed",16,100)
    tog("Survival","JumpPower+","jpEnabled")
    sld("Survival","JumpPower","jumppower",50,200)
    sec("Survival","MISC")
    tog("Survival","Anti-AFK","antiAFK",setAFK)
    tog("Survival","Anti-AFK Advanced","antiAFKPlus",setAFKPlus)
    tog("Survival","Gravity Mod","gravityMod",setGravity)
    sld("Survival","Gravity Value","gravityValue",10,300)

    sec("TP","QUICK")
    btn("TP","→ Nearest Big Tree",function() local d=scan() if #d.big>0 then tp(d.big[1]) end end)
    btn("TP","→ Nearest Tree",function() local d=scan() if #d.t>0 then tp(d.t[1]) end end)
    btn("TP","→ Nearest Chest",function() local d=scan() if #d.c>0 then tp(d.c[1]) end end)
    btn("TP","→ Nearest Enemy",function() local d=scan() if #d.e>0 then tp(d.e[1]) end end)
    btn("TP","→ Nearest Item",function() local d=scan() if #d.i>0 then tp(d.i[1].p.Position) end end)
    btn("TP","→ Nearest Player",function() local d=scan() if #d.p>0 then tp(d.p[1].pl) end end)
    btn("TP","→ Nearest Gem",function() local d=scan() if #d.g>0 then tp(d.g[1].p.Position) end end)
    btn("TP","→ Nearest Rescue",function() local d=scan() if #d.r>0 then
        local x=d.r[1] if x.m then tp(x.m) else tp(x.p.Position) end
    end end)
    sec("TP","SAVED POSITIONS")
    btn("TP","Save Current Position",function()
        local h=hrp() if not h then return end
        table.insert(C.savedPos,{n="Pos"..#C.savedPos+1,cf=h.CFrame})
        print("Saved #"..#C.savedPos)
    end)
    btn("TP","→ Last Saved",function()
        if #C.savedPos>0 then tp(C.savedPos[#C.savedPos].cf) end
    end)
    btn("TP","Clear Saved",function() C.savedPos={} print("Cleared") end)
    sec("TP","TELEPORT FRIEND")
    btn("TP","→ TP to First Player",function()
        for _,pl in ipairs(P:GetPlayers()) do
            if pl~=plr then tp(pl) break end
        end
    end)

    sec("Visuals","ESP ENTITIES")
    tog("Visuals","ESP Enemy","espEnemy")
    tog("Visuals","ESP Player","espPlayer")
    tog("Visuals","ESP Rescue NPC","espRescue")
    sec("Visuals","ESP RESOURCES")
    tog("Visuals","ESP Tree","espTree")
    tog("Visuals","ESP Chest","espChest")
    tog("Visuals","ESP Item","espItem")
    tog("Visuals","ESP Gem","espGem")
    tog("Visuals","ESP Log","espLog")
    tog("Visuals","ESP Scrap","espScrap")
    tog("Visuals","ESP Food","espFood")
    tog("Visuals","ESP Fuel","espFuel")
    sec("Visuals","ESP STYLE")
    tog("Visuals","Show Name","espName")
    tog("Visuals","Show Distance","espDist")
    tog("Visuals","Show Health","espHealth")
    sld("Visuals","Fill Transparency","espFill",0.1,1)
    sld("Visuals","Text Size","espSize",8,24)
    btn("Visuals","Clear ESP",clearESP)
    sec("Visuals","CROSSHAIR")
    tog("Visuals","Custom Crosshair","crosshair",setCrosshair)
    sld("Visuals","Crosshair Size","crosshairSize",2,20)
    sec("Visuals","LIGHTING")
    tog("Visuals","Full Bright","fullbright")
    tog("Visuals","No Fog","noFog")

    sec("Misc","CHARACTER")
    btn("Misc","Reset Character",function()
        local h=hum() if h then h.Health=0 end
    end)
    btn("Misc","Respawn",function() plr:LoadCharacter() end)
    btn("Misc","Unstuck (Raise 10 studs)",function()
        local h=hrp() if h then h.CFrame=h.CFrame+Vector3.new(0,10,0) end
    end)
    tog("Misc","Character Scale","scaleEnabled",function(v)
        if v then setScale(C.scaleValue) end
    end)
    sld("Misc","Scale Value","scaleValue",0.5,3)
    sec("Misc","SERVER")
    btn("Misc","Server Hop",function()
        pcall(function()
            local servers=HS:JSONDecode(game:HttpGet(
                "https://games.roblox.com/v1/games/"..game.PlaceId..
                "/servers/Public?sortOrder=Asc&limit=100"))
            for _,s in ipairs(servers.data or {}) do
                if s.playing<s.maxPlayers and s.id~=game.JobId then
                    TServ:TeleportToPlaceInstance(game.PlaceId,s.id,plr)
                    return
                end
            end
        end)
    end)
    btn("Misc","Rejoin Server",function() TServ:Teleport(game.PlaceId,plr) end)
    sec("Misc","PERFORMANCE")
    sld("Misc","Scan Interval","scanInterval",0.3,2)
    sld("Misc","ESP Interval","espInterval",0.05,0.5)
    sld("Misc","Fling Interval","flingInterval",0.05,0.5)
    sld("Misc","Remote Dedupe","remDedupe",0.05,0.5)
    btn("Misc","Perf Info",function()
        local c=countTbl(S.esp)
        print(("[FT Perf] ScanCache:%d | ESP Objs:%d | Remotes cached:%d")
            :format(S.scanCount,c,countTbl(S.cache)))
    end)
    sec("Misc","AUTOMATION")
    tog("Misc","Auto Screenshot","autoSS")
    sld("Misc","SS Interval","ssInterval",10,300)
    sec("Misc","DEBUG")
    tog("Misc","Jitter","jitter")
    btn("Misc","Dump Scan",function()
        local d=scan(true)
        print(("E:%d T:%d BIG:%d F:%d I:%d C:%d P:%d G:%d L:%d S:%d FD:%d FU:%d R:%d")
            :format(#d.e,#d.t,#d.big,#d.f,#d.i,#d.c,#d.p,#d.g,#d.l,#d.s,#d.fd,#d.fu,#d.r))
    end)
    btn("Misc","List Remotes",function()
        for _,r in ipairs(RS:GetDescendants()) do
            if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then print(r.ClassName,r.Name) end
        end
    end)
    btn("Misc","Show Stats",function()
        print(("K:%d C:%d F:%d B:%d Items:%d Chests:%d Wall:%d Revive:%d Drop:%d Pickup:%d"):format(
            S.count.k,S.count.c,S.count.f,S.count.b,S.count.items,S.count.chest,
            S.count.wall,S.count.revive,S.count.drop,S.count.pickup))
    end)
    btn("Misc","Reset Stats",function() for k in pairs(S.count) do S.count[k]=0 end end)

    return g
end

local gui=ui()
S.con=R.Heartbeat:Connect(hb)

if C.stealth then
    task.delay(3,function()
        pcall(enableSpoof)
        pcall(blockSuspicious)
    end)
end

_G.FT={
    cfg=C,state=S,ui=gui,
    scan=function() return scan(true) end,
    tp=tp,esp=clearESP,
    start=function()
        S.run=true
        if not S.con then S.con=R.Heartbeat:Connect(hb) end
    end,
    stop=function()
        S.run=false
        if S.con then S.con:Disconnect() S.con=nil end
    end,
    spoof=enableSpoof,unspoof=disableSpoof,
    block=blockSuspicious,
    crosshair=setCrosshair,
    scale=setScale,
}

print("═══════════════════════════════════════════")
print("🌲 FOREST TOOLKIT v3.4.3 — Loaded")
print("   UI ready | Stealth sau 3s | No lag")
print("═══════════════════════════════════════════")
