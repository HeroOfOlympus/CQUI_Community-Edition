include("BuilderLens_Support")

-- From GovernorSupport.lua
-- modified to catch unappointed errors
function GetAppointedGovernor(playerID:number, governorTypeIndex:number)
    -- Make sure we're looking for a valid governor
    if playerID == nil or playerID < 0 or governorTypeIndex == nil or governorTypeIndex < 0 then
        return nil;
    end

    -- Get the player governor list
    local pGovernorDef = GameInfo.Governors[governorTypeIndex];
    if pGovernorDef ~= nil then
        local pPlayer:table = Players[playerID];
        local pPlayerGovernors:table = pPlayer:GetGovernors();
        local bHasGovernors, tGovernorList = pPlayerGovernors:GetGovernorList();

        -- Find and return the governor from the governor list
        if pPlayerGovernors:HasGovernor(pGovernorDef.Hash) then
            for i,governor in ipairs(tGovernorList) do
                if governor:GetType() == governorTypeIndex then
                    return governor;
                end
            end
        end
    end

    -- Return nil if this player has not appointed that governor
    return nil;
end

-- ===========================================================================
-- Add rules for builder lens
-- ===========================================================================

-- NATIONAL PARK
--------------------------------------
table.insert(GetConfigRules("COLOR_BUILDER_LENS_PN"),
    function(pPlot)
        local localPlayer = Game.GetLocalPlayer()
        if pPlot:GetOwner() == localPlayer then
            if pPlot:IsNationalPark() then
                return GetColorForNothingPlot()
            end
        end
        return -1
    end)


-- RESOURCE
--------------------------------------
table.insert(GetConfigRules("COLOR_BUILDER_LENS_P1"),
    function(pPlot)
        local localPlayer = Game.GetLocalPlayer()
        local pPlayer:table = Players[localPlayer]
        if pPlot:GetOwner() == localPlayer and not plotHasDistrict(pPlot) then
            if playerHasDiscoveredResource(pPlayer, pPlot) then
                if plotHasImprovement(pPlot) then
                    if plotHasCorrectImprovement(pPlot) then
                        return GetColorForNothingPlot()
                    end
                end

                if plotResourceImprovable(pPlayer, pPlot) then
                    -- If the plot is within working range go ahead with correct highlight
                    if plotWithinWorkingRange(pPlayer, pPlot) then
                        return GetConfiguredColor("COLOR_BUILDER_LENS_P1")
                    else
                        -- If the plot is outside working range, it is less important
                        -- We still might want to suggest it because of vital strategic resource / luxury, or a unique wonder
                        -- that can provide bonuses to it example (Temple of Artemis)
                        return GetConfiguredColor("COLOR_BUILDER_LENS_P1N")
                    end
                else
                    return GetColorForNothingPlot()
                end
            end
        end
        return -1
    end)


-- GEOTHERMAL PLANTS (Only add if exists)
--------------------------------------
if GameInfo.Improvements["IMPROVEMENT_GEOTHERMAL_PLANT"] ~= nil then
    table.insert(GetConfigRules("COLOR_BUILDER_LENS_P2"),
        function(pPlot)
            local localPlayer = Game.GetLocalPlayer()
            local pPlayer:table = Players[localPlayer]
            if pPlot:GetOwner() == localPlayer and not plotHasDistrict(pPlot) and not plotHasImprovement(pPlot)
                    and plotHasFeature(pPlot) then

                local featureInfo = GameInfo.Features[pPlot:GetFeatureType()]
                if featureInfo.FeatureType == "FEATURE_GEOTHERMAL_FISSURE" then
                    local plantImprovInfo = GameInfo.Improvements["IMPROVEMENT_GEOTHERMAL_PLANT"]
                    if playerCanHave(pPlayer, plantImprovInfo) then
                        return GetConfiguredColor("COLOR_BUILDER_LENS_P2")
                    end
                end
            end
        end)
end


-- SEASIDE RESORTS
--------------------------------------
table.insert(GetConfigRules("COLOR_BUILDER_LENS_P2"),
    function(pPlot)
        local localPlayer = Game.GetLocalPlayer()
        local pPlayer:table = Players[localPlayer]
        local resortImprovInfo = GameInfo.Improvements["IMPROVEMENT_BEACH_RESORT"]
        local iAppeal = pPlot:GetAppeal()
        if pPlot:GetOwner() == localPlayer and not pPlot:IsMountain() and not plotHasDistrict(pPlot)
                and iAppeal >= resortImprovInfo.MinimumAppeal
                and pPlot:GetImprovementType() ~= resortImprovInfo.Index then

            if plotCanHaveImprovement(pPlayer, pPlot, resortImprovInfo) then
                return GetConfiguredColor("COLOR_BUILDER_LENS_P2")
            end
        end
    end)


-- SKI RESORTS (Only add if exists)
--------------------------------------
if GameInfo.Improvements["IMPROVEMENT_SKI_RESORT"] ~= nil then
    table.insert(GetConfigRules("COLOR_BUILDER_LENS_P2"),
        function(pPlot)
            local localPlayer = Game.GetLocalPlayer()
            local pPlayer:table = Players[localPlayer]
            if pPlot:GetOwner() == localPlayer and not plotHasDistrict(pPlot) and not plotHasImprovement(pPlot)
                    and pPlot:IsMountain() then

                local resortImprovInfo = GameInfo.Improvements["IMPROVEMENT_SKI_RESORT"]
                if plotCanHaveImprovement(pPlayer, pPlot, resortImprovInfo)
                        and not plotHasAdjImprovement(pPlot, "IMPROVEMENT_SKI_RESORT") then
                    return GetConfiguredColor("COLOR_BUILDER_LENS_P2")
                end
            end
        end)
end


-- PILLAGED / UA
--------------------------------------
table.insert(GetConfigRules("COLOR_BUILDER_LENS_P2"),
    function(pPlot)
        local localPlayer = Game.GetLocalPlayer()
        if pPlot:GetOwner() == localPlayer and not plotHasDistrict(pPlot) then
            if plotHasImprovement(pPlot) and pPlot:IsImprovementPillaged() then
                return GetConfiguredColor("COLOR_BUILDER_LENS_P2")
            end
        end
        return -1
    end)


-- IGNORE PLOTS (Performance optimizations)
--------------------------------------
table.insert(GetConfigRules("COLOR_BUILDER_LENS_P3"),
    function(pPlot)
        -- Non local player plots
        local localPlayer = Game.GetLocalPlayer()
        if pPlot:GetOwner() ~= localPlayer then
            return GetIgnorePlotColor()  -- special flag to completely ignore coloring
        end

        -- Districts. Assume unique abilities are handled earlier (P2 typically)
        if plotHasDistrict(pPlot) then
            return GetColorForNothingPlot()
        end

        -- If an improvement is here, assume we are done with this plot
        if plotHasImprovement(pPlot) then
            return GetColorForNothingPlot()
        end

        -- Mountains or impassable wonders
        if pPlot:IsImpassable() then
            return GetColorForNothingPlot()
        end

        -- Outside of working range can be ignored from here on out
        local pPlayer:table = Players[localPlayer]
        if not plotWithinWorkingRange(pPlayer, pPlot) then
            return GetColorForNothingPlot()
        end
    end)


-- RECOMMENDED PLOTS
--------------------------------------
-- These are generic plots, but have some buff on it that can make it desirable to improve
table.insert(GetConfigRules("COLOR_BUILDER_LENS_P3"),
    function(pPlot)
        local localPlayer = Game.GetLocalPlayer()
        local pPlayer:table = Players[localPlayer]

        if plotHasFeature(pPlot) then
            local featureInfo = GameInfo.Features[pPlot:GetFeatureType()]
            if featureInfo.NaturalWonder then
                return GetColorForNothingPlot()
            end

            -- 1. Non-hill woods next to river (lumbermill)
            -- Check for modifier existing because a patch removed this bonus
            local lumberImprovInfo = GameInfo.Improvements["IMPROVEMENT_LUMBER_MILL"]
            if GameInfo.Modifiers["LUMBER_MILL_RIVERADJACENCY_PRODUCTION"] ~= nil and (not pPlot:IsHills())
                    and featureInfo.FeatureType == "FEATURE_FOREST" and pPlot:IsRiver()
                    and playerCanHave(pPlayer, lumberImprovInfo) then

                return GetConfiguredColor("COLOR_BUILDER_LENS_P3")
            end

            -- 2. Floodplains
            --[[
                local farmImprovInfo = GameInfo.Improvements["IMPROVEMENT_FARM"]
                local spitResult = Split(featureInfo.FeatureType, "_")
                if #spitResult > 1 and spitResult[2] == "FLOODPLAINS" and playerCanHave(pPlayer, farmImprovInfo) then
                    return GetConfiguredColor("COLOR_BUILDER_LENS_P3")
                end
            ]]

            local canHaveImpr:boolean = plotCanHaveSomeImprovement(pPlayer, pPlot)

            -- 3. Volconic soil or tile next to buffing wonder
            if featureInfo.FeatureType == "FEATURE_VOLCANIC_SOIL" and canHaveImpr then
                return GetConfiguredColor("COLOR_BUILDER_LENS_P3")
            end

            -- 4. Wonder buffed tile
            if plotNextToBuffingWonder(pPlot) and canHaveImpr then
                return GetConfiguredColor("COLOR_BUILDER_LENS_P3")
            end
        end

        -- 5. Currently worked tile that does not have a improvement but can have one
        if plotWorkedByCitizen(pPlot) and plotCanHaveSomeImprovement(pPlayer, pPlot) then
            return GetConfiguredColor("COLOR_BUILDER_LENS_P3")
        end
        return -1
    end)


-- HILLS
--------------------------------------
-- Typically hills have a base +1 Production hence any improvement on top of it is desirable
table.insert(GetConfigRules("COLOR_BUILDER_LENS_P4"),
    function(pPlot)
        local localPlayer = Game.GetLocalPlayer()
        local pPlayer:table = Players[localPlayer]
        if pPlot:IsHills() and plotCanHaveSomeImprovement(pPlayer, pPlot) then
            return GetConfiguredColor("COLOR_BUILDER_LENS_P4")
        end
        return -1
    end)


-- EXTRACTABLE FEATURE
--------------------------------------
table.insert(GetConfigRules("COLOR_BUILDER_LENS_P5"),
    function(pPlot)
        local localPlayer = Game.GetLocalPlayer()
        local pPlayer:table = Players[localPlayer]
        if plotHasYieldExtractingFeature(pPlayer, pPlot) then
            return GetConfiguredColor("COLOR_BUILDER_LENS_P5")
        end
        return -1
    end)


-- GENERIC (Last rule)
--------------------------------------
table.insert(GetConfigRules("COLOR_BUILDER_LENS_P7"),
    function(pPlot)
        local localPlayer = Game.GetLocalPlayer()
        local pPlayer:table = Players[localPlayer]

        -- Can we build any improvement add it here
        if plotCanHaveSomeImprovement(pPlayer, pPlot) then
            return GetConfiguredColor("COLOR_BUILDER_LENS_P7")
        end

        -- Assume at this point we can't do anything
        return GetColorForNothingPlot()
    end)
