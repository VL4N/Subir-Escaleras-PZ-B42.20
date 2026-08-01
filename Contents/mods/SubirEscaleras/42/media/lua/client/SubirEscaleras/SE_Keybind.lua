--
-- Subir Escaleras - tecla para trepar
-- Build 42.20
--
-- Mantener pulsada la tecla (E por defecto) junto a una escalera sube o baja
-- por ella sin pasar por el menu de clic derecho.
--
-- Se exige mantenerla en vez de un toque porque E es la tecla "Interact" del
-- juego: un toque abriria puertas o pasaria por ventanas al mismo tiempo.
--
-- El nombre que se ve en Opciones sale de
-- getText("UI_optionscreen_binding_" .. value), ver MainOptions.lua:2182.
-- Por eso el identificador es ASCII y el texto visible va en Translate/.
--

-- Un servidor no tiene teclado ni tabla keyBinding que ampliar, y los eventos
-- OnKey* no existen ahi. Salimos antes de tocar nada.
if isServer() then return end

require "SubirEscaleras/SE_Utils"
require "SubirEscaleras/SE_ClimbAction"
require "TimedActions/WalkToTimedAction"

local BIND_NAME = "SubirEscaleras_Climb"

local bind = {}
bind.value = "[SubirEscaleras]"
table.insert(keyBinding, bind)

bind = {}
bind.value = BIND_NAME
bind.key = Keyboard.KEY_E
table.insert(keyBinding, bind)

local heldTicks = 0
local alreadyFired = false

--- Escalera relevante desde donde esta el jugador: primero a su altura (subir)
--- y si no un nivel por debajo (bajar).
--- Devuelve: objeto, direccion, cuadroDeLaEscalera, bajando
local function findLadderForPlayer(playerSquare)
    local x, y, z = playerSquare:getX(), playerSquare:getY(), playerSquare:getZ()

    local ladder, dir, ladderSquare = SubirEscaleras.findLadderNear(x, y, z)
    if ladder then return ladder, dir, ladderSquare, false end

    ladder, dir, ladderSquare = SubirEscaleras.findLadderNear(x, y, z - 1)
    if ladder then return ladder, dir, ladderSquare, true end

    return nil
end

--- true si el jugador esta escribiendo: el chat se come las teclas y no hay que
--- reaccionar a ellas. Sin esto, escribir una palabra con E estando al lado de
--- una escalera lanzaba la trepada en mitad de la frase.
local function isTyping()
    return ISChat and ISChat.instance and ISChat.instance.textEntry
        and ISChat.instance.textEntry:isFocused()
end

--- true si ya se esta trepando. Soltar y volver a mantener E durante la accion
--- vaciaba la cola y la reiniciaba desde cero una y otra vez.
local function alreadyClimbing(playerObj)
    -- Comprobado a mano en vez de con pcall: esto corre en cada pulsacion, y
    -- si en alguna build faltara el metodo, un error aqui seria justo el tipo
    -- de goteo en consola que este mod ya no quiere producir.
    if not ISTimedActionQueue or not ISTimedActionQueue.getTimedActionQueue then
        return false
    end

    local queue = ISTimedActionQueue.getTimedActionQueue(playerObj)
    local current = queue and queue.queue and queue.queue[1]
    return current ~= nil and current.Type == "ISSubirEscaleraAction"
end

local function climbNow()
    local playerObj = getSpecificPlayer(0)
    if not playerObj or playerObj:isDead() then return end
    if playerObj:getVehicle() then return end
    if isTyping() then return end
    if alreadyClimbing(playerObj) then return end

    local playerSquare = playerObj:getCurrentSquare()
    if not playerSquare then return end

    local ladder, dir, ladderSquare, down = findLadderForPlayer(playerSquare)
    if not ladder then return end

    -- A partir de aqui se habla por el personaje, y siempre con enfriamiento:
    -- E es la tecla de interactuar, asi que estando al lado de una escalera se
    -- pasa por aqui constantemente sin querer trepar.
    local canClimb, reason = SubirEscaleras.canClimb(playerObj, down)
    if not canClimb then
        SubirEscaleras.say(playerObj, reason)
        return
    end

    local target = SubirEscaleras.getTargetSquare(ladderSquare, down, dir)
    if not target then
        SubirEscaleras.say(playerObj, "IGUI_SubirEscaleras_Inseguro")
        return
    end

    -- de donde se sale: al subir, la propia escalera; al bajar, lo alto de ella
    local startSquare = ladderSquare
    if down then
        startSquare = SubirEscaleras.findLanding(ladderSquare:getX(), ladderSquare:getY(),
            playerSquare:getZ(), dir) or playerSquare
    end

    ISTimedActionQueue.clear(playerObj)
    if playerObj:getCurrentSquare() ~= startSquare then
        ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, startSquare))
    end
    ISTimedActionQueue.add(ISSubirEscaleraAction:new(playerObj, ladder, ladderSquare,
        startSquare, target, down))
end

local function isOurKey(key)
    return getCore():isKey(BIND_NAME, key)
end

local function onKeyStartPressed(key)
    if not isOurKey(key) then return end
    heldTicks = 0
    alreadyFired = false
end

local function onKeyKeepPressed(key)
    if not isOurKey(key) then return end
    if alreadyFired then return end
    if isTyping() then return end

    heldTicks = heldTicks + 1
    if heldTicks < SubirEscaleras.holdTicks then return end

    -- una sola vez por pulsacion: hasta soltar y volver a pulsar no repite
    alreadyFired = true
    climbNow()
end

Events.OnKeyStartPressed.Add(onKeyStartPressed)
Events.OnKeyKeepPressed.Add(onKeyKeepPressed)
