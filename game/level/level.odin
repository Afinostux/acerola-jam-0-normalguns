package level

import "core:fmt"
import "core:strconv"
import "core:encoding/xml"
import "core:math/linalg"

import "../clip"
import "../util"

LEVELSRC: = [?][]u8{
    //test
    #load("../../test.tmx"),
}

Obstacle:: struct {
    position: [2]f32,
    size: [2]f32,
}

Level:: struct {
    id:        int,
    obstacles: [dynamic]Obstacle,
    climbable: [dynamic]Obstacle,
}

//TODO(AFOX): maybe enemies need to be their own package for organizational reasons
EnemyCreateType:: enum {
    Boxer,
    Hover,
    Hoverbomb,
    Saw,
    Shield,
}

EnemyCreateInfo:: struct {
    type:     EnemyCreateType,
    position: [2]f32,
    flip:     bool,
}

createEnemies: [dynamic]EnemyCreateInfo

create_enemy:: proc(type: EnemyCreateType, position: [2]f32, flip: bool)
{
    append(&createEnemies, EnemyCreateInfo{
        type     = type,
        position = position,
        flip     = flip,
    })
}

overlaps:: proc(
    obstacle: []Obstacle,
    position: [2]f32,
    size: [2]f32,
) -> (overlap: bool)
{
    for c in obstacle {
        cl, _: = clip.aabb_aabb(position, size, c.position, c.size)
        if cl {
            return true
        }
    }
    return false
}

move_point_to_climbable:: proc(
    climbable: []Obstacle,
    position: [2]f32,
) -> (move: [2]f32)
{
    bestDistance: = max(f32)
    for c in climbable {
        inside, difference: = clip.aabb_point_difference(position, c.position, c.size)
        if inside { return {} }
        if linalg.length2(difference) < bestDistance {
            bestDistance = linalg.length2(difference)
            move = difference
        }
    }
    return move
}

move_rect_to_climbable:: proc(
    climbable: []Obstacle,
    position: [2]f32,
    size: [2]f32,
) -> (move: [2]f32)
{
    corners: = [4][2]f32{
        position,
        position + {0, size.y},
        position + {size.x, 0},
        position + size,
    }

    moves: [4][2]f32

    for i in 0..<4 {
        moves[i] = move_point_to_climbable(climbable, corners[i])
    }

    return util.largest(moves[:])
}

deviolate_obstacles:: proc(
    obstacles: []Obstacle,
    position: [2]f32,
    size: [2]f32,
) -> (clipped: bool, move: [2]f32)
{
    position: = position
    for _ in 0..<2 {
        score: = min(f32)
        bestOverlap: [2]f32

        for obs in obstacles {
            cl, overlap: = clip.aabb_aabb(position, size, obs.position, obs.size)
            if cl {
                clipped = true
                la: = linalg.abs(overlap)
                ls: = clip.area(la)
                if ls > score {
                    score = ls
                    if la.x < la.y {
                        bestOverlap = {overlap.x, 0}
                    } else {
                        bestOverlap = {0, overlap.y}
                    }
                }
            }
        }

        position += bestOverlap
        move += bestOverlap
    }
    return clipped, move
}

unload:: proc(level: ^Level)
{
    delete(level.obstacles)
    level^ = {}
}

enemyPrefabMap: = map[string]EnemyCreateType {
    "editor_prefab/boxerbot.tx"     = .Boxer,
    "editor_prefab/hoverbotBomb.tx" = .Hoverbomb,
    "editor_prefab/hoverbot.tx"     = .Hover,
    "editor_prefab/sawbot.tx"       = .Saw,
    "editor_prefab/shieldbot.tx"    = .Shield,
}

load:: proc(id: int) -> (level: Level)
{
    load_obstacles:: proc(level: ^Level, doc: ^xml.Document, root: xml.Element_ID)
    {
        obstacle:     Obstacle
        positionPart: = [2]string{ "x", "y" }
        sizePart:     = [2]string{ "width", "height" }

        for i in doc.elements[root].value {
            id: = i.(xml.Element_ID) or_else max(u32)
            if id == max(u32) { continue }
            for j in 0..<2 {
                obstacle.position[j] = 0
                part, found: = xml.find_attribute_val_by_key(doc, id, positionPart[j])
                if !found { continue }
                num, ok: = strconv.parse_f32(part)
                if !ok { continue }
                obstacle.position[j] = num
            }
            for j in 0..<2 {
                obstacle.size[j] = 0
                part, found: = xml.find_attribute_val_by_key(doc, id, sizePart[j])
                if !found { continue }
                num, ok: = strconv.parse_f32(part)
                if !ok { continue }
                obstacle.size[j] = num
            }
            append(&level.obstacles, obstacle)
        }
    }

    load_climbable:: proc(level: ^Level, doc: ^xml.Document, root: xml.Element_ID)
    {
        obstacle:     Obstacle
        positionPart: = [2]string{ "x", "y" }
        sizePart:     = [2]string{ "width", "height" }

        for i in doc.elements[root].value {
            id: = i.(xml.Element_ID) or_else max(u32)
            if id == max(u32) { continue }
            for j in 0..<2 {
                obstacle.position[j] = 0
                part, found: = xml.find_attribute_val_by_key(doc, id, positionPart[j])
                if !found { continue }
                num, ok: = strconv.parse_f32(part)
                if !ok { continue }
                obstacle.position[j] = num
            }
            for j in 0..<2 {
                obstacle.size[j] = 0
                part, found: = xml.find_attribute_val_by_key(doc, id, sizePart[j])
                if !found { continue }
                num, ok: = strconv.parse_f32(part)
                if !ok { continue }
                obstacle.size[j] = num
            }
            append(&level.climbable, obstacle)
        }
    }

    //<object id="19" template="editor_prefab/boxerbot.tx" x="304" y="-184"/>
    //<object id="20" template="editor_prefab/hoverbotBomb.tx" x="-408" y="-188"/>
    //<object id="21" template="editor_prefab/hoverbot.tx" x="-406.667" y="22.6667"/>
    //<object id="22" template="editor_prefab/sawbot.tx" x="-268" y="344"/>
    //<object id="23" template="editor_prefab/shieldbot.tx" x="274.667" y="334.667"/>
    //<object id="24" template="editor_prefab/hoverbot.tx" x="202.667" y="0"/>
    //<object id="26" template="editor_prefab/sawbot.tx" x="-120" y="181.333"/>
    //<object id="27" template="editor_prefab/sawbot.tx" gid="2147483652" x="112" y="169.333" rotation="0"/>

    load_enemies:: proc(doc: ^xml.Document, root: xml.Element_ID)
    {
        positionPart: = [2]string{ "x", "y" }
        for i in doc.elements[root].value {
            id: = i.(xml.Element_ID) or_else max(u32)
            if id == max(u32) { continue }
            type: EnemyCreateType
            position: [2]f32
            flip: bool
            if template, templateFound: = xml.find_attribute_val_by_key(doc, id, "template"); templateFound {
                type = enemyPrefabMap[template]
            } else { continue }
            for j in 0..<2 {
                part, found: = xml.find_attribute_val_by_key(doc, id, positionPart[j])
                if !found { continue }
                num, ok: = strconv.parse_f32(part)
                if !ok { continue }
                position[j] = num
            }
            if _, flipFound: = xml.find_attribute_val_by_key(doc, id, "gid"); flipFound {
                flip = true
            }
            create_enemy(type, position, flip)
        }
    }

    doc, err: = xml.parse_bytes(LEVELSRC[id])
    for i in doc.elements[0].value {
        id: = i.(xml.Element_ID) or_else max(u32)
        if id == max(u32) { continue }
        element: = doc.elements[id]
        if element.ident == "objectgroup" {
            if val, found: = xml.find_attribute_val_by_key(doc, id, "name"); found {
                switch val {
                    case "obstacles":
                    load_obstacles(&level, doc, id)
                    case "climbable":
                    load_climbable(&level, doc, id)
                    case "enemies":
                    load_enemies(doc, id)
                }
            }
        }
    }
    return level
}
