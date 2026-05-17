export type Flag = {
    [string]: any
}

export type Flags = {
    CompressionLevel: (number) -> Flag,

    CFrameSerializeMethod: {
        Attributes: boolean,
        Bytes: (
            PositionFormat: "F16" | "F32" | "F64", 
            RotationFormat: "F16" | "F32" | "F64"
        ) -> Flag
    },
}


local function CreateCallFlag(key, default)
    return setmetatable({
        [key] = default
    }, {
        __call = function(self, value)
            self[key] = value
            return self
        end
    })
end

local function CreateOptionFlag(key, default, options)
    return setmetatable({
        [key] = default
    }, { 
        __index = function(self, idx)
            local opt = options[idx]
            if not opt then
                return self
            end

            if typeof(opt) == "function" then
                return function(...)
                    local optData = opt(...)

                    if typeof(optData) == "table" then
                        for key, value in optData do    
                            self[key] = value
                        end
                    end

                    return self
                end
            end

            for key, value in opt do    
                self[key] = value
            end

            return self
        end
    })
end


local _Flags = {
    CompressionLevel = CreateCallFlag("CompressionLevel", 7),
    CFrameSerializeMethod = CreateOptionFlag("CFrameSerializeMethod", "Bytes", { 
        Attributes = { CFrameSerializeMethod = "Attributes", CFrameRotSizeT = 4, CFramePosSizeT = 4, },
        Bytes = function(posT, rotT)
            return { 
                CFrameSerializeMethod = "Bytes", 
                CFramePosSizeT = (tonumber(posT:sub(2)) or 32) / 8,
                CFrameRotSizeT = (tonumber(rotT:sub(2)) or 32) / 8,
            }
        end
    })
}

local Default = {
    CompressionLevel = 7,
    CFrameSerializeMethod = "Bytes",
    CFrameRotSizeT = 4, 
    CFramePosSizeT = 4,
}


local Flags: Flags = setmetatable({}, { 
    __index = function(self, key) 
        local existingFlag = _Flags[key]
        local meta = getmetatable(existingFlag) or {}
  
        local call = meta.__call
        local index = meta.__index

        return setmetatable(
            table.clone(Default), 
            {
                __call = call,
                __index = index,

                __add = function(flags, newFlag)
                    for key, value in newFlag do
                        flags[key] = value
                    end

                    return flags
                end
            }
        )
    end
})

return Flags