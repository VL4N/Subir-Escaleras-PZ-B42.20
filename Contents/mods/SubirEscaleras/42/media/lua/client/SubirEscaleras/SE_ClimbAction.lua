--
-- Subir Escaleras - accion temporizada
-- Build 42.20
--
-- Animacion: NO se puede usar la de trepar cuerdas (clip Bob_ClimbRope).
-- Ese "climbrope" no es una capa de animacion sino un estado completo del
-- personaje: con la variable ClimbRope a true el motor deja de aplicar la
-- colision con el suelo (asi es como se atraviesan los pisos al trepar), y
-- sin cuerda de verdad el personaje se hunde.
--
-- Usamos la capa "actions", que entra como substate cuando IsPerformingAnAction
-- es true y no toca la fisica del personaje.
-- Ver media/actiongroups/player/idle/to_actions.xml
--

require "TimedActions/ISBaseTimedAction"
require "SubirEscaleras/SE_Utils"

ISSubirEscaleraAction = ISBaseTimedAction:derive("ISSubirEscaleraAction")

function ISSubirEscaleraAction:isValid()
    if not self.target then return false end
    if not SubirEscaleras.isStandable(self.target) then return false end

    local current = self.character:getCurrentSquare()
    if not current then return false end
    if not self.startSquare then return true end

    -- hay que estar en el punto de partida o pegado a el
    return current == self.startSquare or current:isAdjacentTo(self.startSquare)
end

function ISSubirEscaleraAction:waitToStart()
    if self.ladder then
        self.character:faceThisObject(self.ladder)
    end
    return self.character:shouldBeTurning()
end

function ISSubirEscaleraAction:start()
    self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", self.down and "Low" or "High")
    self:setOverrideHandModels(nil, nil)

    -- Se resuelve una sola vez, aqui. Estaba dentro de update(), que corre en
    -- cada tick de la accion: si la tabla Metabolics no tuviera esa entrada,
    -- eran ochenta trazas de error por escalera en vez de una.
    self.metabolicTarget = Metabolics and Metabolics.ClimbRope or nil
    if not self.metabolicTarget then
        SubirEscaleras.warnOnce("metabolics", "Metabolics.ClimbRope no existe; se trepa sin coste metabolico")
    end
end

function ISSubirEscaleraAction:update()
    if self.metabolicTarget then
        self.character:setMetabolicTarget(self.metabolicTarget)
    end
end

function ISSubirEscaleraAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISSubirEscaleraAction:perform()
    local current = self.character:getCurrentSquare()
    local native = false

    -- solo dejamos que lo haga el motor si el destino cae en la misma columna
    -- que la escalera y a un solo nivel: si hay que salir a un cuadro de al
    -- lado nos dejaria en el aire, y si son varios niveles se quedaria corto
    local sameColumn = self.target:getX() == self.ladderSquare:getX()
            and self.target:getY() == self.ladderSquare:getY()
    local oneLevel = math.abs(self.target:getZ() - self.ladderSquare:getZ()) <= 1

    if sameColumn and oneLevel and current == self.ladderSquare then
        if self.down then
            native = self.character:canClimbDownSheetRope(current)
        else
            native = self.character:canClimbSheetRope(current)
        end
    end

    if native then
        if self.down then
            self.character:climbDownSheetRope()
        else
            self.character:climbSheetRope()
        end
    else
        SubirEscaleras.moveSafely(self.character, self.target, current)
    end

    SubirEscaleras.spendEndurance(self.character,
        SubirEscaleras.enduranceCost * self.levels * self.load)

    ISBaseTimedAction.perform(self)
end

function ISSubirEscaleraAction:new(character, ladder, ladderSquare, startSquare, target, down)
    local o = ISBaseTimedAction.new(self, character)
    o.ladder = ladder
    o.ladderSquare = ladderSquare
    o.startSquare = startSquare
    o.target = target
    o.down = down

    -- una escalera puede cruzar varios niveles: cuesta tiempo y aliento por cada uno
    local fromZ = (startSquare or ladderSquare):getZ()
    o.levels = math.max(1, math.abs(target:getZ() - fromZ))

    -- ir pasado de peso lo hace mas lento y mas cansado
    o.load = SubirEscaleras.getLoadFactor(character)

    o.maxTime = SubirEscaleras.climbTime * o.levels * o.load
    if character:isTimedActionInstant() then o.maxTime = 1 end
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end

-- Red de seguridad: una version anterior de este mod ponia ClimbRope a true
-- para reproducir la animacion de trepar. Si algun personaje se quedo con la
-- variable puesta, seguiria atravesando el suelo. La limpiamos al aparecer.
--
-- Va en pcall porque isClimbingRope() no esta garantizado en todas las builds
-- de B42, y esto corre al entrar en la partida: si peta, revienta el resto de
-- handlers de OnCreatePlayer que vengan detras, no solo el nuestro.
Events.OnCreatePlayer.Add(function(playerNum, playerObj)
    if not playerObj then return end

    local ok = pcall(function()
        if not playerObj:isClimbingRope() then
            playerObj:setVariable("ClimbRope", false)
        end
    end)

    if not ok then
        SubirEscaleras.warnOnce("climbrope", "no se ha podido comprobar ClimbRope al aparecer")
    end
end)
