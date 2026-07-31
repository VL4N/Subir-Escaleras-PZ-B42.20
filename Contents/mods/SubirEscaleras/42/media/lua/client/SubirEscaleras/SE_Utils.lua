--
-- Subir Escaleras - utilidades compartidas
-- Build 42.20
--

SubirEscaleras = SubirEscaleras or {}

-- Ponlo en true para que aparezca la opcion "[Escaleras] Volcar info a la
-- consola" en el menu de clic derecho. Escribe en C:\Users\<usuario>\Zomboid\console.txt
SubirEscaleras.debug = true

-- Tiempo (en ticks de accion) que tarda el personaje en subir o bajar.
SubirEscaleras.climbTime = 80

-- Cansancio que cuesta cada tramo de escalera.
SubirEscaleras.enduranceCost = 0.03

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
-- fia de las banderas: reconoce la escalera por el nombre del sprite y hace
-- el movimiento por su cuenta.
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
        for dir, flag in pairs(SubirEscaleras.climbFlags) do
            if props:has(flag) then return dir end
        end
        for dir, key in pairs(ladderKeys) do
            if props:has(key) then return dir end
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
function SubirEscaleras.isStandable(square)
    if not square then return false end
    if square:getZ() > 0 and not square:getFloor() then return false end
    if square:isSolid() then return false end
    if square:isSolidTrans() then return false end
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

    local candidates = { { 0, 0 } }
    if dir and stepOff[dir] then
        table.insert(candidates, stepOff[dir])
    end
    for _, offset in pairs(stepOff) do
        table.insert(candidates, offset)
    end

    for _, offset in ipairs(candidates) do
        local square = cell:getGridSquare(x + offset[1], y + offset[2], z)
        if SubirEscaleras.isStandable(square) then
            return square, exact
        end
    end

    return nil, exact
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
    local offsets = { { 0, 0 }, { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }
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

    local ok = pcall(function() character:teleportTo(x, y, z) end)
    if not ok then
        character:setX(x)
        character:setY(y)
        character:setZ(z)
        pcall(function()
            character:setLx(x)
            character:setLy(y)
            character:setLz(z)
        end)
    end
    pcall(function() character:setCurrent(square) end)
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
