--
-- Subir Escaleras - utilidades compartidas
-- Build 42.20
--

SubirEscaleras = SubirEscaleras or {}

-- Ponlo en true para que aparezca la opcion "[Escaleras] Volcar info a la
-- consola" en el menu de clic derecho. Escribe en C:\Users\<usuario>\Zomboid\console.txt
SubirEscaleras.debug = false

-- Tiempo (en ticks de accion) que tarda el personaje en subir o bajar.
SubirEscaleras.climbTime = 80

-- Cansancio que cuesta cada tramo de escalera.
SubirEscaleras.enduranceCost = 0.03

-- Impide trepar hacia arriba con una pierna o un pie rotos sin entablillar.
SubirEscaleras.blockIfInjured = true

-- Aliento minimo para empezar a subir (1 = descansado, 0 = reventado).
SubirEscaleras.minEndurance = 0.10

-- Cuanto mas cuesta subir yendo pasado de peso, como maximo.
SubirEscaleras.overloadPenalty = 2.0

-- Fotogramas que hay que mantener pulsada la tecla para que empiece a trepar.
-- Se pide mantenerla, y no un toque, para no pisar la interaccion normal de E
-- (abrir puertas, pasar por ventanas). Unos 20 son algo menos de medio segundo.
SubirEscaleras.holdTicks = 20

-- Milisegundos que tiene que pasar para repetir la misma frase del personaje.
-- E es la tecla de interactuar: si estas al lado de una escalera y agotado,
-- sin esto sale el bocadillo cada vez que la tocas.
SubirEscaleras.sayCooldown = 5000

--
-- MENSAJES
--
-- Nada de lo que escriba este mod en consola debe poder repetirse sin freno.
-- console.txt es compartido: un mod que escupe una linea por tick tapa los
-- errores de todos los demas y hace imposible diagnosticar nada.
--

--- Escribe en consola solo en modo debug.
function SubirEscaleras.log(message)
    if SubirEscaleras.debug then
        print("[SubirEscaleras] " .. message)
    end
end

local warned = {}

--- Avisa de un problema una unica vez por partida, aunque se repita mil veces.
function SubirEscaleras.warnOnce(id, message)
    if warned[id] then return end
    warned[id] = true
    print("[SubirEscaleras] " .. message)
end

local lastSaid = {}

--- Bocadillo con enfriamiento, para no repetir la misma frase sin parar.
function SubirEscaleras.say(character, key)
    if not character then return end

    local ok, playerNum = pcall(function() return character:getPlayerNum() end)
    local id = key .. "@" .. tostring(ok and playerNum or 0)

    local now = getTimestampMs()
    if lastSaid[id] and now - lastSaid[id] < SubirEscaleras.sayCooldown then
        return
    end
    lastSaid[id] = now

    character:Say(getText(key))
end

--
-- ACCESO A LAS ESTADISTICAS
--
-- getStats():getEndurance() es la via de siempre. El acceso por
-- CharacterStat.ENDURANCE se queda como alternativa: si esa tabla global no
-- existe en la build que tenga el jugador, indexarla lanza un error, y este
-- codigo corre al abrir el menu contextual y en cada tick de la accion. Un
-- error ahi son cientos de trazas en consola, no una.
--

--- Aliento actual, de 0 (reventado) a 1 (descansado).
function SubirEscaleras.getEndurance(character)
    local ok, value = pcall(function() return character:getStats():getEndurance() end)
    if ok and value then return value end

    ok, value = pcall(function() return character:getStats():get(CharacterStat.ENDURANCE) end)
    if ok and value then return value end

    SubirEscaleras.warnOnce("endurance", "no se ha podido leer el aliento; se ignora ese limite")
    return 1
end

--- Gasta aliento. Nunca baja de 0.
function SubirEscaleras.spendEndurance(character, amount)
    local ok = pcall(function()
        local stats = character:getStats()
        stats:setEndurance(math.max(0, stats:getEndurance() - amount))
    end)
    if ok then return end

    ok = pcall(function()
        character:getStats():remove(CharacterStat.ENDURANCE, amount)
    end)
    if ok then return end

    SubirEscaleras.warnOnce("endurance_set", "no se ha podido gastar aliento al trepar")
end

--
-- RED DE SEGURIDAD, no la via principal.
--
-- La deteccion normal lee las propiedades del sprite en caliente (ver
-- getClimbDir), asi que funciona con cualquier escalera aunque no este aqui.
-- Esta lista solo cubre el caso de que esa lectura falle.
--
-- Son las 18 escaleras del juego base en B42.20, sacadas de escanear los 7
-- archivos .tiles buscando propiedades ladder* / climbSheet*.
--
-- La direccion es la letra de la propiedad ladderN/S/E/W del tiledef: el lado
-- por el que se sale. Comprobado con dos escaleras distintas en el mapa
-- (ladderN sale al norte, ladderS sale al sur).
--
-- Varias de estas NO traen la propiedad climbSheet* en el juego base, que es
-- justo el motivo de que el motor no te deje treparlas. Por eso el mod no se
-- fia solo de las banderas y hace el movimiento por su cuenta.
--
SubirEscaleras.ladderSprites = {
    ["industry_railroad_05_20"] = "W",  -- escalera metalica movible (madera)
    ["industry_railroad_05_21"] = "N",
    ["industry_railroad_05_36"] = "W",  -- escalera metalica movible (acero)
    ["industry_railroad_05_37"] = "N",  -- <- a esta le falta climbSheetN
    ["industry_railroad_05_56"] = "E",  -- escalera fija de pared (ocupa 2 niveles)
    ["industry_railroad_05_57"] = "S",
    ["industry_railroad_05_58"] = "E",
    ["industry_railroad_05_59"] = "S",
    ["location_sewer_01_32"]    = "W",  -- escalera de alcantarilla
    ["location_sewer_01_33"]    = "N",
    ["location_sewer_01_48"]    = "E",
    ["location_sewer_01_49"]    = "S",
    ["carpentry_02_84"]         = "W",  -- escalera de madera
    ["carpentry_02_85"]         = "N",
    ["carpentry_02_86"]         = "E",
    ["carpentry_02_87"]         = "S",
    ["advertising_01_6"]        = "W",  -- escalera de valla publicitaria
    ["advertising_01_14"]       = "N",
}

SubirEscaleras.climbFlags = {
    N = IsoFlagType.climbSheetN,
    S = IsoFlagType.climbSheetS,
    E = IsoFlagType.climbSheetE,
    W = IsoFlagType.climbSheetW,
}

-- Orden fijo en el que se prueban las direcciones.
--
-- IMPORTA, y mucho: antes se recorrian las tablas de arriba con pairs(), que en
-- Lua no garantiza ningun orden. Una escalera con dos banderas climbSheet* (o
-- dos propiedades ladder*, que las hay) devolvia una direccion u otra segun le
-- diera, y con ella cambiaba la casilla por la que te bajabas. Ese es el
-- "funciona a veces" que se ve desde fuera como que el mod va a saltos.
local climbDirs = { "N", "S", "E", "W" }

-- desplazamiento para bajarse de la escalera segun a que lado esta pegada
local stepOff = {
    N = { 0, -1 },
    S = { 0,  1 },
    W = { -1, 0 },
    E = {  1, 0 },
}

local topFlags = {
    IsoFlagType.climbSheetTopN,
    IsoFlagType.climbSheetTopS,
    IsoFlagType.climbSheetTopE,
    IsoFlagType.climbSheetTopW,
}

-- nombre de la propiedad de tiledef que marca la direccion de salida
local ladderKeys = { N = "ladderN", S = "ladderS", E = "ladderE", W = "ladderW" }

--- Devuelve la direccion de salida ("N"/"S"/"E"/"W"), "?" si es una escalera
--- pero no se sabe por donde se sale, o nil si no es trepable.
---
--- Va de lo mas fiable a lo mas generico:
---   1. banderas climbSheet* del motor
---   2. propiedades ladderN/S/E/W del tiledef  <- cubre cualquier escalera,
---      del juego base o de otro mod, sin tener que listarla
---   3. lista de sprites conocidos, como red de seguridad
---   4. CustomName "Ladder"/"Ladders" o un sprite que se llame "...ladder..."
---      (mods que no marcan la direccion). Direccion desconocida: se prueban
---      los cuatro lados.
function SubirEscaleras.getClimbDir(object)
    if not object then return nil end

    local props = object:getProperties()

    if props then
        for _, dir in ipairs(climbDirs) do
            if props:has(SubirEscaleras.climbFlags[dir]) then return dir end
        end
        for _, dir in ipairs(climbDirs) do
            if props:has(ladderKeys[dir]) then return dir end
        end
    end

    local sprite = object:getSprite()
    local name = sprite and sprite:getName()

    if name and SubirEscaleras.ladderSprites[name] then
        return SubirEscaleras.ladderSprites[name]
    end

    if props and props:has("CustomName") then
        local custom = props:get("CustomName")
        if custom == "Ladder" or custom == "Ladders" then return "?" end
    end

    if name and string.find(string.lower(name), "ladder", 1, true) then
        return "?"
    end

    return nil
end

local legParts = {
    BodyPartType.Foot_L,     BodyPartType.Foot_R,
    BodyPartType.LowerLeg_L, BodyPartType.LowerLeg_R,
    BodyPartType.UpperLeg_L, BodyPartType.UpperLeg_R,
}

--- true si tiene una pierna o un pie rotos y sin entablillar.
--- Entablillada no cuenta: el juego ya distingue los dos casos
--- (ver ISHealthPanel.lua:740).
function SubirEscaleras.hasBrokenLeg(character)
    local damage = character:getBodyDamage()
    if not damage then return false end

    for _, partType in ipairs(legParts) do
        local part = damage:getBodyPart(partType)
        if part and part:getFractureTime() > 0 and part:getSplintFactor() == 0 then
            return true
        end
    end

    return false
end

--- Cuanto multiplica el esfuerzo ir cargado. 1 = dentro de capacidad.
function SubirEscaleras.getLoadFactor(character)
    local maxWeight = character:getMaxWeight()
    if not maxWeight or maxWeight <= 0 then return 1 end

    local ratio = character:getInventoryWeight() / maxWeight
    if ratio <= 1 then return 1 end

    return math.min(SubirEscaleras.overloadPenalty, 1 + (ratio - 1) * 2)
end

--- Si el personaje puede subir. Devuelve: bool, clave de texto del motivo.
---
--- Bajar NUNCA se bloquea, a proposito: dejar a alguien tirado en un tejado sin
--- forma de bajar es peor que cualquier realismo, y la alternativa seria saltar.
function SubirEscaleras.canClimb(character, down)
    if down then return true end

    if SubirEscaleras.blockIfInjured and SubirEscaleras.hasBrokenLeg(character) then
        return false, "IGUI_SubirEscaleras_Pierna"
    end

    local endurance = SubirEscaleras.getEndurance(character)
    if endurance and endurance < SubirEscaleras.minEndurance then
        return false, "IGUI_SubirEscaleras_Agotado"
    end

    return true
end

--- true si el objeto es el remate superior de una escalera.
function SubirEscaleras.isClimbTop(object)
    if not object then return false end
    local props = object:getProperties()
    if not props then return false end
    for _, flag in ipairs(topFlags) do
        if props:has(flag) then return true end
    end
    return false
end

--- Busca el primer objeto trepable dentro de un cuadro.
--- Devuelve objeto, direccion.
function SubirEscaleras.findLadder(square)
    if not square then return nil end
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        local dir = SubirEscaleras.getClimbDir(object)
        if dir then
            return object, dir
        end
    end
    return nil
end

--- true si el personaje puede quedarse de pie en ese cuadro.
---
--- Usa TreatAsSolidFloor(), la misma comprobacion con la que el juego decide
--- si puedes caminar a un cuadro (ver ISWalkToCursor:isValid en el Lua base).
--- Antes se usaba getFloor() ~= nil, que da falsos positivos: hay cuadros con
--- un objeto de suelo que aun asi no te sostienen. Por eso un jugador acabo
--- cayendo desde arriba y murio.
function SubirEscaleras.isStandable(square)
    if not square then return false end
    if square:isSolid() then return false end
    if square:isSolidTrans() then return false end
    if not square:TreatAsSolidFloor() then return false end
    return true
end

--- Busca un cuadro donde poder estar de pie en la columna (x,y) al nivel z.
--- Prueba primero el propio (x,y,z); si ahi no hay suelo (lo normal cuando la
--- escalera pasa por un hueco), prueba el cuadro al que da la escalera y
--- despues el resto de vecinos.
--- Devuelve: cuadroValido, cuadroExacto(x,y,z)
function SubirEscaleras.findLanding(x, y, z, dir)
    if z < 0 or z > 31 then return nil, nil end

    local cell = getCell()
    local exact = cell:getGridSquare(x, y, z)

    -- La propia casilla primero, luego el lado al que da la escalera y despues
    -- el resto, siempre en el mismo orden. Con pairs() el orden lo decidia el
    -- hash de la tabla, asi que la misma escalera te dejaba en un vecino
    -- distinto cada vez que la usabas.
    local candidates = { { 0, 0 } }
    local used = { ["0,0"] = true }

    local function addCandidate(offset)
        if not offset then return end
        local id = offset[1] .. "," .. offset[2]
        if used[id] then return end
        used[id] = true
        table.insert(candidates, offset)
    end

    addCandidate(dir and stepOff[dir])
    for _, d in ipairs(climbDirs) do
        addCandidate(stepOff[d])
    end

    -- Primera pasada: solo cuadros a los que de verdad se puede salir desde la
    -- escalera. isSomethingTo dice si hay una pared, ventana o puerta entre dos
    -- cuadros contiguos; sin esta comprobacion el personaje acaba metido dentro
    -- del muro y el motor lo expulsa al primer paso que da.
    local fallback = nil

    for _, offset in ipairs(candidates) do
        local square = cell:getGridSquare(x + offset[1], y + offset[2], z)
        if SubirEscaleras.isStandable(square) then
            local sameSquare = offset[1] == 0 and offset[2] == 0
            local blocked = false

            if not sameSquare and exact then
                local ok, result = pcall(function() return exact:isSomethingTo(square) end)
                blocked = ok and result
            end

            if sameSquare or not blocked then
                return square, exact
            end

            fallback = fallback or square
        end
    end

    -- Segunda pasada: si todas las salidas estan tapiadas, mejor dejarlo en una
    -- con suelo que no ofrecer nada. Se movera raro, pero no se cae.
    return fallback, exact
end

--- Recorre la columna mientras siga habiendo escalera y devuelve el z del
--- ultimo tramo. Muchas escaleras del mapa ocupan varios niveles: si encima
--- todavia hay escalera, es que no se ha acabado y no hay que bajarse ahi.
function SubirEscaleras.findLadderEnd(x, y, z, up)
    local cell = getCell()
    local step = up and 1 or -1
    local endZ = z

    for _ = 1, 31 do
        local nz = endZ + step
        if nz < 0 or nz > 31 then break end
        local square = cell:getGridSquare(x, y, nz)
        if not square then break end
        if not SubirEscaleras.findLadder(square) then break end
        endZ = nz
    end

    return endZ
end

--- A donde lleva la escalera. Sube (o baja) hasta el final de la escalera y
--- sale un nivel mas alla del ultimo tramo. Si ahi no hay donde pisar, va
--- probando niveles hacia atras hasta el punto de partida.
--- Devuelve: cuadroDestino, cuadroIdeal
function SubirEscaleras.getTargetSquare(ladderSquare, down, dir)
    if not ladderSquare then return nil, nil end

    local x, y = ladderSquare:getX(), ladderSquare:getY()
    local z0 = ladderSquare:getZ()
    local endZ = SubirEscaleras.findLadderEnd(x, y, z0, not down)

    local first, last, step
    if down then
        first, last, step = endZ, z0, 1
    else
        first, last, step = endZ + 1, z0 + 1, -1
    end

    local ideal = getCell():getGridSquare(x, y, first)

    for z = first, last, step do
        local square = SubirEscaleras.findLanding(x, y, z, dir)
        if square then return square, ideal end
    end

    return nil, ideal
end

--- Busca una escalera en la columna alrededor de (x,y) a la altura z.
--- Devuelve: objeto, direccion, cuadroDeLaEscalera
function SubirEscaleras.findLadderNear(x, y, z)
    local cell = getCell()
    -- 3x3 completo. Las escaleras pegadas al borde norte u oeste dibujan su
    -- sprite sobre el muro, asi que el clic cae en una casilla vecina y no en
    -- la que ocupa la escalera. Con solo las cuatro cardinales se escapaban.
    local offsets = {
        { 0, 0 },
        { 0, -1 }, { -1, 0 }, { 0, 1 }, { 1, 0 },
        { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 },
    }
    for _, offset in ipairs(offsets) do
        local square = cell:getGridSquare(x + offset[1], y + offset[2], z)
        local ladder, dir = SubirEscaleras.findLadder(square)
        if ladder then
            return ladder, dir, square
        end
    end
    return nil
end

--- Mueve al personaje a un cuadro.
function SubirEscaleras.movePlayerTo(character, square)
    local x = square:getX() + 0.5
    local y = square:getY() + 0.5
    local z = square:getZ()

    -- Primero el cuadro y despues la posicion, nunca al reves: setCurrent deja
    -- al personaje en el origen del cuadro (x.0, y.0), que es la esquina noroeste
    -- y suele coincidir con la pared. Si se llama despues de centrarlo, lo
    -- descoloca y aparece metido dentro del muro hasta que da un paso.
    pcall(function() character:setCurrent(square) end)

    local ok = pcall(function() character:teleportTo(x, y, z) end)

    -- El centrado se fuerza SIEMPRE, no solo si teleportTo falla: tanto
    -- setCurrent como teleportTo dejan al personaje en el origen del cuadro
    -- (x.0, y.0), que es la esquina noroeste y suele ser la pared.
    character:setX(x)
    character:setY(y)
    character:setZ(z)

    SubirEscaleras.log(string.format("movido a %d,%d,%d teleportTo=%s pos=%.2f,%.2f,%.2f",
        square:getX(), square:getY(), square:getZ(), tostring(ok),
        character:getX(), character:getY(), character:getZ()))
end

--- Mueve al personaje y lo vigila un momento. Si acaba en un cuadro donde no
--- se puede pisar (o sea, se ha puesto a caer), lo devuelve al punto de
--- partida en vez de dejarlo estamparse. Red de seguridad: la comprobacion
--- previa del destino deberia bastar, pero una caida mata.
function SubirEscaleras.moveSafely(character, target, origin)
    SubirEscaleras.movePlayerTo(character, target)
    if not origin then return end

    local ticks = 0
    local watchdog

    -- Todo el cuerpo va dentro de un pcall y el evento se suelta pase lo que
    -- pase.
    --
    -- Antes no: si el personaje dejaba de ser valido (muere, se desconecta,
    -- cambia de celda), character:isDead() lanzaba, el error subia desde el
    -- handler y la linea que quita el evento no llegaba a ejecutarse. El
    -- handler seguia enganchado y volvia a petar al tick siguiente. Se cortaba
    -- solo a los 30 ticks, pero de casualidad: la condicion empieza por
    -- ticks >= 30, y en cuanto se cumple Lua ya no evalua el isDead() que
    -- petaba. O sea, 29 trazas completas en console.txt por cada salto fallido
    -- en vez de ninguna, y bastaba con reordenar esa condicion para que no
    -- parasen nunca.
    watchdog = function()
        ticks = ticks + 1

        local ok, done = pcall(function()
            if ticks >= 30 or not character or character:isDead() then
                return true
            end

            local square = character:getCurrentSquare()

            if square and not SubirEscaleras.isStandable(square) then
                SubirEscaleras.movePlayerTo(character, origin)
                SubirEscaleras.log("destino inseguro, devuelto al punto de partida")
                SubirEscaleras.say(character, "IGUI_SubirEscaleras_Inseguro")
                return true
            end

            return false
        end)

        if ok and not done then return end

        Events.OnTick.Remove(watchdog)

        if not ok then
            SubirEscaleras.warnOnce("watchdog",
                "la vigilancia post-salto fallo y se ha soltado; " ..
                "activa SubirEscaleras.debug si se repite")
        end
    end

    Events.OnTick.Add(watchdog)
end

--- Vuelca en consola todo lo que hay en el cuadro (modo debug).
function SubirEscaleras.dumpSquare(square)
    if not square then
        print("[SubirEscaleras] cuadro nulo")
        return
    end
    print(string.format("[SubirEscaleras] --- cuadro %d,%d,%d ---",
        square:getX(), square:getY(), square:getZ()))
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local object = objects:get(i)
        local sprite = object:getSprite()
        local name = sprite and sprite:getName() or "(sin sprite)"
        local dir = SubirEscaleras.getClimbDir(object)
        print(string.format("[SubirEscaleras]   sprite=%s  trepable=%s  remate=%s",
            tostring(name), tostring(dir), tostring(SubirEscaleras.isClimbTop(object))))
    end
    print(string.format("[SubirEscaleras]   suelo=%s solido=%s",
        tostring(square:getFloor() ~= nil), tostring(square:isSolid())))
end
