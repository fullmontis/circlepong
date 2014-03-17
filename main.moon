-- Component ID
CID = {}
CID.POSITION = 1
CID.IMAGE = 2
CID.CAMERA = 3
CID.MOVEABLE = 4
CID.VELOCITY = 5
CID.RECT = 6
CID.CIRCLE = 7

-- Entity ID
EID = {}
EID.POWER = 1
EID.PADDLE = 2
EID.BALL = 3
EID.FIELD = 4
EID.CAMERA = 5

-- System ID
-- Per fare in modo che siano eseguiti nell'ordine imposto
-- è necessario che non ci siano "buchi"
SID = {}
SID.MOVEMENT = 1
SID.INPUT = 2
SID.COLLIDE = 3
SID.MOVEBALL = 4
SID.CAMERA = 5
SID.RECT = 6
SID.CIRCLE = 7
SID.RENDER = 8

PASSIVE = 2
ACTIVE = 1

nballs = 1
alreadycreated = false


gettablesize = (t) ->
    c = 0
    for k,v in pairs(t)
        c += 1
    return c

getindexof = (t,val) ->
    for k,v in pairs(t)
        if v == val
            return k

-- Inserts a value in a table and returns the index at which the value is
insert = (t,v) ->
    table.insert(t,v)
    k = getindexof(t,v)
    return k

-- Generates coordinates x and y randomly inside a circle of radius r
generateXY = (r)->
    angle = math.random()*math.pi*2
    x = math.cos(angle)*r
    y = math.sin(angle)*r
    return x,y
    
    
getEntitiesWithComponents = (componentList) ->
        entitiesList = {}
        for eid,entity in pairs(manager.entities)
            useable = true
            for _,needed in pairs(componentList)
                if not entity.components[needed]
                    useable = false
            if useable
                table.insert(entitiesList,entity)
        return entitiesList
        
        
getEntitiesWithId = (id) ->
        entitiesList = {}
        for eid,entity in pairs(manager.entities)
            if entity.id == id
                table.insert(entitiesList,entity)
        return entitiesList
        
        
class Entity
    new: ()=>
        @components = {}
        @index = 0
    removeSelf: ()=>
        self = nil
    addComponent: (component) =>
        @components[component.id] = component
    removeComponent: (id) =>
        @components[id] = nil
    setId: (id) =>
        @id = id
        
        
class Manager
    new: =>
        @entities = {}
        @systems = {}
        @states = {}
        @dt = 0
        @paused = false
        
    addState: (state) =>
        i = insert(@states,state)
        return i
    
    activateState: (stateId) =>
        @systems = @states[stateId].systems
        @entities = @states[stateId].entities
    
    update: (actionType) =>
        if @paused 
            actionType = PASSIVE
        for _,system in pairs(@systems)
            if system.actionType == actionType
                elist = getEntitiesWithComponents(system.neededComponents)
                for _,entity in pairs(elist)
                    system\update(entity,@dt)


    addEntity: (entity) =>
        entity.index = insert(@entities,entity)
        return entity.index
    
    removeEntity: (entity) =>
        @entities[entity.index] = nil
    
    pause: =>
        @paused = true
    
    resume: =>
        @paused = false
    
    isPaused: =>
        return @paused

class State
    new: =>
        @entities = {}
        @systems = {}
    
    addSystem: (system) =>
        @systems[system.id] = system
        
    removeSystem: (id) =>
        @systems[id] = nil
                
    addEntity: (entity) =>
        entity.index = insert(@entities,entity)
        return entity.index
        

class SInput
    new: =>
        @id = SID.INPUT
        @neededComponents = {CID.POSITION,CID.MOVEABLE}
        @actionType = ACTIVE
        
    update: (e,dt) =>
        with e.components[CID.POSITION]
        
            angle = math.atan2(.y,.x)

            if love.keyboard.isDown "left"
                angle += math.pi/2*dt
            if love.keyboard.isDown "right"
                angle -= math.pi/2*dt
                
            .x = math.cos(angle)*rpaddle    
            .y = math.sin(angle)*rpaddle  
            
class SMoveBall
    new: =>
        @id = SID.MOVEBALL
        @neededComponents = {CID.POSITION,CID.VELOCITY}
        @actionType = ACTIVE
    update: (e,dt) =>
        xvel = e.components[CID.VELOCITY].x
        yvel = e.components[CID.VELOCITY].y
        
        with e.components[CID.POSITION]
            .x += xvel*dt
            .y += yvel*dt

class SCircle
    new: =>
        @id = SID.CIRCLE
        @neededComponents = {CID.CIRCLE,CID.POSITION}
        @actionType = PASSIVE
    update: (e,dt) =>
        with e.components[CID.POSITION]
            love.graphics.circle(e.components[CID.CIRCLE].style,.x,.y,e.components[CID.CIRCLE].r)
            
            
class SRect
    new: =>
        @id = SID.RECT
        @neededComponents = {CID.RECT,CID.POSITION}
        @actionType = PASSIVE
    update: (e,dt) =>
        with e.components[CID.POSITION]
            angle = math.atan2(.y,.x)            
            w = e.components[CID.RECT].w
            h = e.components[CID.RECT].h
            love.graphics.push()
            love.graphics.translate(.x,.y)
            love.graphics.rotate(angle+math.pi/2)
            love.graphics.rectangle(e.components[CID.RECT].style,-w/2,-h/2,w,h)
            love.graphics.pop()
                
            
class SRender
    new: =>
        @id = SID.RENDER
        @neededComponents = {CID.IMAGE,CID.POSITION}
        @actionType = PASSIVE
        
    update: (e,dt) =>
        love.graphics.draw(e.components[CID.IMAGE].image, e.components[CID.POSITION].x, e.components[CID.POSITION].y)


class SBallCollide
    new: =>
        @id = SID.COLLIDE
        @neededComponents = {CID.POSITION,CID.CIRCLE,CID.VELOCITY}
        @actionType = ACTIVE
        
    update: (ball,dt) =>
       
        bx = ball.components[CID.POSITION].x
        by = ball.components[CID.POSITION].y
        
        br = math.sqrt(bx*bx+by*by)
        bangle = math.atan2(by,bx)
        bvx = ball.components[CID.VELOCITY].x
        bvy = ball.components[CID.VELOCITY].y
        bsize = ball.components[CID.CIRCLE].r
        
        -- Check collision with paddles
        paddles = getEntitiesWithId(EID.PADDLE)
        
        for _,paddle in pairs(paddles)
            px = paddle.components[CID.POSITION].x
            py = paddle.components[CID.POSITION].y            
            pr = math.sqrt(px*px+py*py)
            pangle = math.atan2(py,px)
            pw = paddle.components[CID.RECT].w
            ph = paddle.components[CID.RECT].h

            alpha = bangle-pangle
            alphamax = math.atan2(pw/2, pr-ph/2)
            
            -- projection on the paddle axis of the velocity components
            bvxlocal = bvx*math.cos(pangle)+bvy*math.sin(pangle)
            bvylocal = bvx*math.sin(pangle)-bvy*math.cos(pangle)
            
            -- projection of the radius connection the ball with the center on the radius connecting the paddle with the center
            brproj = math.cos(alpha)*br
            
            if math.abs(brproj+bsize) > math.abs(pr-ph/2) and alpha>-alphamax and alpha<alphamax and bvxlocal>0
                bvxlocal = -bvxlocal
                ball.components[CID.VELOCITY].x = bvxlocal*math.cos(pangle) + bvylocal*math.sin(pangle)
                ball.components[CID.VELOCITY].y = bvxlocal*math.sin(pangle) - bvylocal*math.cos(pangle)
                --ball.components[CID.VELOCITY].x *= 1.3 
                --ball.components[CID.VELOCITY].y *= 1.3
            
        -- Collision with the boundaries
        if math.abs(br+bsize) > math.abs(rfield)
            if nballs == 1
                randx,randy = generateXY(ballspeed)
                ball.components[CID.POSITION].x = 0
                ball.components[CID.POSITION].y = 0
                ball.components[CID.VELOCITY].x = randx
                ball.components[CID.VELOCITY].y = randy
            else
                manager\removeEntity(ball)
                nballs -= 1
                
        powers = getEntitiesWithId(EID.POWER)
        for _,power in pairs(powers)
            px = power.components[CID.POSITION].x
            py = power.components[CID.POSITION].y
            pr = power.components[CID.CIRCLE].r
            
            -- Collision with the powerup
            if bx > px-pr and bx < px+pr and by > py-pr and by < py+pr and nballs<5 and not alreadycreated
                randx, randy = generateXY(rpaddle-80)
                power.components[CID.POSITION].x = randx
                power.components[CID.POSITION].y = randy
                alreadycreated = true
                print manager\addEntity(newball())
                nballs += 1
            
class SCamera
    new: =>
        @id = SID.CAMERA
        @neededComponents = {CID.CAMERA}
        @actionType = PASSIVE
        
    update: (e,dt) =>
        with e.components[CID.CAMERA]
            --.angle += 1.2*dt 
            love.graphics.translate(.x,.y)
            love.graphics.rotate(.angle)

class CPosition
    new: (x,y) =>
        @id = CID.POSITION
        @x,@y = x,y
        
        
class CImage
    new: (image) =>
        @id = CID.IMAGE
        @image = image


class CCamera
    new: (x,y,angle) =>
        @id = CID.CAMERA
        @x,@y,@angle = x,y,angle


class CMoveable
    new: =>
        @id = CID.MOVEABLE


class CCircle
    new: (r,style)=>
        @id = CID.CIRCLE
        @r = r
        @style = style


class CVelocity
    new: (x,y) =>
        @id = CID.VELOCITY
        @x,@y = x,y


class CRect
    new: (w,h,style) =>
        @id = CID.RECT
        @w = w
        @h = h
        @style = style
        
    
export newball = ->
    e = Entity()
    e\addComponent(CCircle(rball,"fill"))
    e\addComponent(CPosition(0,0))
    randx, randy = generateXY(ballspeed)
    e\addComponent(CVelocity(randx,randy))
    e\setId(EID.BALL)
    return e
    
newpower = ->
    e = Entity()
    e\addComponent(CCircle(rball+10,"fill"))
    randx, randy = generateXY(rpaddle-80)
    e\addComponent(CPosition(randx,randy))
    e\setId(EID.POWER)
    return e
    
newfield = ->
    e = Entity()
    e\addComponent(CPosition(0,0))
    e\addComponent(CCircle(rfield,"line"))
    e\setId(EID.FIELD)
    return e
    
newplayer = ->
    e = Entity()
    e\addComponent(CPosition(0,rpaddle))
    e\addComponent(CMoveable())
    e\addComponent(CRect(paddlewidth,paddleheigth,"fill"))
    e\setId(EID.PADDLE)
    return e
    
newcamera = ->
    e = Entity()
    e\addComponent(CCamera(circlex,circley,0))
    e\setId(EID.CAMERA)
    return e
    
love.load = ->
    width = love.graphics.getWidth()
    height = love.graphics.getHeight()
    
    export circlex = width/2
    export circley = height/2
    export paddlewidth = 150
    export paddleheigth = 20
    export rfield = 268
    export rpaddle = rfield - 50  
    export rball = 10
    export manager = Manager()
    export ballspeed = 80
    
    gameState = State()
    gameState\addSystem(SRender())
    gameState\addSystem(SInput())
    gameState\addSystem(SCamera())
    gameState\addSystem(SRect())
    gameState\addSystem(SCircle())
    gameState\addSystem(SMoveBall())
    gameState\addSystem(SBallCollide())
    
    gameState\addEntity(newcamera())
    gameState\addEntity(newplayer())
    gameState\addEntity(newfield())
    gameState\addEntity(newball())
    gameState\addEntity(newpower())
    
    GAMESTATEID = manager\addState(gameState)
    manager\activateState(GAMESTATEID)

loaded = false
pressed = false
pressedold = false

love.update =  (dt) ->
    manager.dt = dt
    manager\update(ACTIVE)
    
    if love.keyboard.isDown("r")
        love.load()
        love.filesystem.load("main.lua")()
    if love.keyboard.isDown("x")
        love.filesystem.load("main.lua")()
    
    pressedold = pressed
    pressed = love.keyboard.isDown("p")
    if pressed and not pressedold
        if manager\isPaused()
            manager\resume()
        else
            manager\pause()

nballsold = 0

love.draw = ->
    love.graphics.print love.timer.getFPS(),10,10
    manager\update(PASSIVE)
    
    alreadycreated = false
    
    nballs = gettablesize(getEntitiesWithId(EID.BALL))
    if nballs != nballsold
        nballsold = nballs
        print "n° of balls: ",nballs
    
    
    
    