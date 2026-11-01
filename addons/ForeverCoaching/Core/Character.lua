ForeverCoaching = ForeverCoaching or {}

function ForeverCoaching:GetCharacterInfo()
    local info = {
        name = UnitName("player"),
        level = UnitLevel("player"),
        className = UnitClass("player"),
    }

    return info
end
