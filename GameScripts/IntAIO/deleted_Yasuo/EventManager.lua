local function CanDash(unit)
    local notBUFF = unit.buff[string.lower('YasuoDashWrapper')]
    return not notBUFF
end

return {
    CanDash = CanDash
}