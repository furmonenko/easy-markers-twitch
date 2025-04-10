--[[
Twitch Stream Marker Script for OBS Studio
Version: 3.0.0
Author: evilfurmo with assistance from Claude AI
License: MIT License
Copyright (c) 2025 evilfurmo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--

-- Settings for Twitch API
local obs = obslua
local version = "1.0.0"

-- Your Twitch API credentials
local settings = {
    client_id     = "",  -- Enter your Client ID here
    oauth_token   = "",  -- Enter your OAuth token here
    broadcaster_id = "", -- Enter your Broadcaster ID here
    debug_mode    = true
}

-- Script variables
local hotkey_id = obs.OBS_INVALID_HOTKEY_ID
local marker_count = 0
local temp_dir = os.getenv("TEMP") or os.getenv("TMP") or "."
local script_path = ""

-- Logging functions
local function log_debug(message)
    if settings.debug_mode then
        print("[Twitch Marker] " .. message)
    end
end

local function log_error(message)
    print("[Twitch Marker ERROR] " .. message)
end

local function log_success(message)
    print("[Twitch Marker SUCCESS] " .. message)
end

-- Function to write temporary file
local function write_temp_file(filename, content)
    local file_path = temp_dir .. "\\" .. filename
    local file = io.open(file_path, "w")
    if not file then
        log_error("Failed to create temporary file: " .. file_path)
        return nil
    end
    
    file:write(content)
    file:close()
    return file_path
end

-- Function to execute HTTP request via curl
local function curl_request(method, url, headers, body)
    local curl_cmd = 'curl -s -X ' .. method .. ' "' .. url .. '"'
    
    -- Add headers
    for k, v in pairs(headers) do
        curl_cmd = curl_cmd .. ' -H "' .. k .. ': ' .. v .. '"'
    end
    
    -- If there's a request body, write it to a temporary file
    if body and body ~= "" then
        local temp_file = write_temp_file("twitch_request.json", body)
        if temp_file then
            curl_cmd = curl_cmd .. ' -d @"' .. temp_file .. '"'
        else
            return nil
        end
    end
    
    log_debug("Executing command: " .. curl_cmd)
    
    -- Use io.popen to get the result
    local handle = io.popen(curl_cmd, "r")
    if not handle then
        log_error("Failed to execute curl request")
        return nil
    end
    
    local response = handle:read("*a")
    local success = handle:close()
    
    if not success then
        log_error("Failed to close request handle")
    end
    
    return response
end

-- Function to check if stream is active
local function check_stream_active()
    log_debug("Checking stream activity...")
    
    local headers = {
        ["Client-ID"] = settings.client_id,
        ["Authorization"] = "Bearer " .. settings.oauth_token
    }
    
    local url = "https://api.twitch.tv/helix/streams?user_id=" .. settings.broadcaster_id
    
    local response = curl_request("GET", url, headers, nil)
    if not response then
        log_error("Failed to get response when checking stream")
        return false
    end
    
    log_debug("API response for stream check: " .. response)
    
    -- Check if we received stream data
    if response:match('"data":%[%]') then
        log_error("Stream is NOT active! Markers can only be created during an active stream.")
        return false
    elseif not response:match('"data":%[{') then
        log_error("Error checking stream status")
        if response:match('"message"') then
            local error_message = response:match('"message":"([^"]+)"')
            log_error("Error message: " .. (error_message or "unknown error"))
        end
        return false
    end
    
    log_success("Stream is active! You can create markers.")
    return true
end

-- Function to check token validity
local function check_token()
    log_debug("Checking OAuth token...")
    
    local headers = {
        ["Client-ID"] = settings.client_id,
        ["Authorization"] = "Bearer " .. settings.oauth_token
    }
    
    local url = "https://api.twitch.tv/helix/users"
    
    local response = curl_request("GET", url, headers, nil)
    if not response then
        log_error("Failed to get response when checking token")
        return false
    end
    
    log_debug("API response for token check: " .. response)
    
    if response:match('"data":%[{') then
        log_success("OAuth token is valid!")
        local user_name = response:match('"login":"([^"]+)"')
        local user_id = response:match('"id":"([^"]+)"')
        
        if user_name and user_id then
            log_success("Authorized as: " .. user_name .. " (ID: " .. user_id .. ")")
            
            -- Check if ID matches broadcaster_id
            if user_id ~= settings.broadcaster_id then
                log_error("WARNING! User ID (" .. user_id .. ") does not match broadcaster_id (" .. settings.broadcaster_id .. ")")
                log_error("You may need to update the broadcaster_id in the script!")
                settings.broadcaster_id = user_id  -- Automatically correct ID
                log_success("Broadcaster ID automatically updated to: " .. settings.broadcaster_id)
            end
        end
        
        return true
    else
        log_error("Problem with OAuth token. API response: " .. response)
        if response:match('"message"') then
            local error_message = response:match('"message":"([^"]+)"')
            log_error("Error message: " .. (error_message or "unknown error"))
        end
        return false
    end
end

-- Function to create stream marker
local function create_stream_marker()
    log_debug("===== STARTING MARKER CREATION =====")
    
    -- Check if stream is active
    if not check_stream_active() then
        log_error("Failed to create marker: stream is not active")
        log_debug("===== ENDING MARKER CREATION =====")
        return
    end
    
    -- Prepare request for marker creation
    local url = "https://api.twitch.tv/helix/streams/markers"
    local headers = {
        ["Client-ID"] = settings.client_id,
        ["Authorization"] = "Bearer " .. settings.oauth_token,
        ["Content-Type"] = "application/json"
    }
    
    local description = "OBS marker " .. os.date("%H:%M:%S")
    local body = '{"user_id":"' .. settings.broadcaster_id .. '","description":"' .. description .. '"}'
    
    log_debug("Prepared request to: " .. url)
    log_debug("Marker description: " .. description)
    log_debug("Request body: " .. body)
    
    -- Send request
    local response = curl_request("POST", url, headers, body)
    if not response then
        log_error("Failed to get response when creating marker")
        log_debug("===== ENDING MARKER CREATION =====")
        return
    end
    
    log_debug("Response from Twitch: [" .. response .. "]")
    log_debug("Response length: " .. response:len() .. " characters")
    
    -- Analyze response
    if response:match('"created_at"') then
        log_success("MARKER SUCCESSFULLY CREATED!")
        
        -- Try to get more details about the created marker
        local position = response:match('"position":([0-9]+)')
        local created_at = response:match('"created_at":"([^"]+)"')
        
        if position and created_at then
            log_success("Created marker at position " .. position .. " seconds, time: " .. created_at)
            log_success("Marker description: " .. description)
        end
        
        -- Update marker counter
        marker_count = marker_count + 1
        log_success("Total number of created markers: " .. marker_count)
    elseif response:match('"error"') then
        local error_message = response:match('"message":"([^"]+)"')
        if error_message then
            log_error("Error from API: " .. error_message)
            
            -- Check for common errors
            if error_message:match("[Mm]issing scope") then
                log_error("Your token lacks required permissions. Add the 'channel:manage:broadcast' scope to your token.")
            elseif error_message:match("[Aa]ccess [Tt]oken") then
                log_error("Problem with access token. Create a new token on dev.twitch.tv.")
            elseif error_message:match("[Ll]ive") or error_message:match("stream") then
                log_error("Stream must be active to create markers.")
            elseif error_message:match("Too many") then
                log_error("Too many markers created. Twitch has a limit on the number of markers.")
            elseif error_message:match("body") or error_message:match("parse") then
                log_error("Problem with JSON formatting. Trying to create marker without description...")
                -- Simplified request without description
                local simple_body = '{"user_id":"' .. settings.broadcaster_id .. '"}'
                local simple_response = curl_request("POST", url, headers, simple_body)
                if simple_response and simple_response:match('"created_at"') then
                    log_success("MARKER SUCCESSFULLY CREATED without description!")
                else
                    log_error("Failed to create marker even without description.")
                end
            end
        else
            log_error("Error creating marker")
        end
    else
        log_error("Unexpected response from Twitch API")
        log_debug("Full response:")
        log_debug(response)
    end
    
    log_debug("===== ENDING MARKER CREATION =====")
end

-- Hotkey press handler
local function on_event(pressed)
    if pressed then
        create_stream_marker()
    end
end

-- OBS functions

function script_description()
    return "Add Twitch stream markers by pressing a hotkey (version " .. version .. ")"
end

function script_properties()
    local props = obs.obs_properties_create()
    
    -- Add fields for editing parameters
    obs.obs_properties_add_text(props, "client_id", "Client ID", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "oauth_token", "OAuth Token", obs.OBS_TEXT_PASSWORD)
    obs.obs_properties_add_text(props, "broadcaster_id", "Broadcaster ID", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_bool(props, "debug_mode", "Debug Mode")
    
    -- Add buttons for testing
    local test_button = obs.obs_properties_add_button(props, "test_button", "Test Marker", 
        function()
            create_stream_marker()
            return true
        end)
    
    local check_token_button = obs.obs_properties_add_button(props, "check_token", "Check Token", 
        function()
            check_token()
            return true
        end)
    
    local check_stream_button = obs.obs_properties_add_button(props, "check_stream", "Check Stream", 
        function()
            check_stream_active()
            return true
        end)
    
    return props
end

function script_update(settings_obj)
    settings.client_id = obs.obs_data_get_string(settings_obj, "client_id") or settings.client_id
    settings.oauth_token = obs.obs_data_get_string(settings_obj, "oauth_token") or settings.oauth_token
    settings.broadcaster_id = obs.obs_data_get_string(settings_obj, "broadcaster_id") or settings.broadcaster_id
    settings.debug_mode = obs.obs_data_get_bool(settings_obj, "debug_mode")
    
    log_debug("Settings updated")
end

function script_defaults(settings_obj)
    obs.obs_data_set_default_string(settings_obj, "client_id", settings.client_id)
    obs.obs_data_set_default_string(settings_obj, "oauth_token", settings.oauth_token)
    obs.obs_data_set_default_string(settings_obj, "broadcaster_id", settings.broadcaster_id)
    obs.obs_data_set_default_bool(settings_obj, "debug_mode", settings.debug_mode)
end

function script_save(settings_obj)
    local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
    obs.obs_data_set_array(settings_obj, "add_twitch_marker", hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)
    log_debug("Settings saved")
end

function script_load(settings_obj)
    log_debug("Loading script version " .. version .. "...")
    
    -- Determine OS type
    log_debug("OS: Windows")
    log_debug("Temporary directory: " .. temp_dir)
    
    -- Register hotkey
    hotkey_id = obs.obs_hotkey_register_frontend("add_twitch_marker", "Add Twitch Marker", on_event)
    local hotkey_save_array = obs.obs_data_get_array(settings_obj, "add_twitch_marker")
    obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)
    
    -- Load settings
    script_update(settings_obj)
    
    -- Display script information
    log_debug("===== SCRIPT INFORMATION =====")
    log_debug("OBS Twitch Marker script version " .. version .. " loaded")
    log_debug("Client ID: " .. (settings.client_id ~= "" and settings.client_id or "not set"))
    
    if settings.oauth_token ~= "" then
        log_debug("OAuth Token (first 10 characters): " .. settings.oauth_token:sub(1, 10) .. "...")
    else
        log_debug("OAuth Token: not set")
    end
    
    log_debug("Broadcaster ID: " .. (settings.broadcaster_id ~= "" and settings.broadcaster_id or "not set"))
    log_debug("Debug mode: " .. (settings.debug_mode and "Enabled" or "Disabled"))
    
    -- Check token if credentials are provided
    if settings.client_id ~= "" and settings.oauth_token ~= "" then
        if check_token() then
            log_success("Token validation successful!")
        else
            log_error("Failed to validate token")
        end
    else
        log_error("Please enter your Twitch API credentials in the script settings")
    end
    
    log_debug("==============================")
    log_debug("Script ready to use. Press the assigned hotkey to create a marker during your stream.")
end