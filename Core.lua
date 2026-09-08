HCChallenger = {}
local HC=HCChallenger

HC.VERSION="0.1.0"
HC.NAME="HC Challenger"
HC.COLORED_NAME="|cffb8c0ccHC|r |cffa335eeChallenger|r"
HC.MODULE="CHL"
HC.MAX_ROUTES=30
HC.MAX_COMMUNITY_ROUTES=25
HC.MAX_STEPS=80
HC.StepTypes={"Travel","Quest","Turn in","Kill","Grind","Train","Craft","Hearth","Flight","Safety","Note"}
HC.Factions={"Both","Alliance","Horde"}
HC.Classes={"Any","Druid","Hunter","Mage","Paladin","Priest","Rogue","Shaman","Warlock","Warrior"}
HC.State={tab="My Routes",routeId=nil,stepIndex=1,routeOffset=0,stepOffset=0,challengeIndex=1,stepTypeIndex=1,factionIndex=1,classIndex=1,communityKey=nil,communityOffset=0,challengeView=1}
HC.Catalog={}
HC.PendingDownloads={}
HC.Transfers={}

function HC:Trim(value,limit)
 value=tostring(value or"");value=string.gsub(value,"|c%x%x%x%x%x%x%x%x","");value=string.gsub(value,"|r","");value=string.gsub(value,"[\r\n]"," ");value=string.gsub(value,"%s+"," ");value=string.gsub(value,"^%s+","");value=string.gsub(value,"%s+$","");if limit and string.len(value)>limit then value=string.sub(value,1,limit)end;return value
end
function HC:Now()if type(time)=="function"then local n=tonumber(time());if n then return n end end;return math.floor(GetTime())end
function HC:GetCharacterKey()local name=UnitName("player")or"Unknown";local realm=GetRealmName and GetRealmName()or"Unknown";return string.lower(name.."-"..realm)end
function HC:GetLocation()return self:Trim(GetRealZoneText and GetRealZoneText()or GetZoneText and GetZoneText()or"Unknown",48),self:Trim(GetSubZoneText and GetSubZoneText()or"",48)end
function HC:GetCoordinates()
 if not GetPlayerMapPosition then return nil,nil end;if WorldMapFrame and WorldMapFrame:IsShown()then return nil,nil end;if SetMapToCurrentZone then SetMapToCurrentZone()end;local x,y=GetPlayerMapPosition("player");x=tonumber(x);y=tonumber(y);if not x or not y or x<=0 or y<=0 or x>1 or y>1 then return nil,nil end;return math.floor(x*1000)/1000,math.floor(y*1000)/1000
end
function HC:GetChallenge(id)local i;for i=1,table.getn(HCChallengerChallenges)do if HCChallengerChallenges[i].id==id then return HCChallengerChallenges[i],i end end;return HCChallengerChallenges[1],1 end
function HC:GetChallengeName(id)local c=self:GetChallenge(id);return c and c.name or"Standard / No challenge"end
function HC:IsValidStepType(value)local i;for i=1,table.getn(self.StepTypes)do if self.StepTypes[i]==value then return 1 end end;return nil end
function HC:IsValidFaction(value)local i;for i=1,table.getn(self.Factions)do if self.Factions[i]==value then return 1 end end;return nil end
function HC:IsValidClass(value)local i;for i=1,table.getn(self.Classes)do if self.Classes[i]==value then return 1 end end;return nil end
function HC:IsValidChallenge(id)local c=self:GetChallenge(id);return c and c.id==id end

function HC:InitializeDB()
 if type(HCChallengerDB)~="table"then HCChallengerDB={}end;if type(HCChallengerDB.settings)~="table"then HCChallengerDB.settings={}end;if type(HCChallengerDB.routes)~="table"then HCChallengerDB.routes={}end;if type(HCChallengerDB.communityRoutes)~="table"then HCChallengerDB.communityRoutes={}end;if type(HCChallengerDB.progress)~="table"then HCChallengerDB.progress={}end
 local s=HCChallengerDB.settings;if s.networkEnabled==nil then s.networkEnabled=nil end;if s.minimap==nil then s.minimap=1 end;if s.minimapAngle==nil then s.minimapAngle=-.2 end;if type(s.position)~="table"then s.position={point="CENTER",relPoint="CENTER",x=0,y=0}end;if type(s.guidePosition)~="table"then s.guidePosition={point="RIGHT",relPoint="RIGHT",x=-30,y=40}end
 HCChallengerDB.schema=1;self.DB=HCChallengerDB;self:PruneData();if table.getn(self.DB.routes)>0 and not self.State.routeId then self.State.routeId=self.DB.routes[1].id end
end
function HC:PruneData()
 while table.getn(self.DB.routes)>self.MAX_ROUTES do table.remove(self.DB.routes)end
 while table.getn(self.DB.communityRoutes)>self.MAX_COMMUNITY_ROUTES do table.remove(self.DB.communityRoutes)end
 local i;for i=1,table.getn(self.DB.routes)do local r=self.DB.routes[i];if type(r.steps)~="table"then r.steps={}end;while table.getn(r.steps)>self.MAX_STEPS do table.remove(r.steps)end end
 for i=1,table.getn(self.DB.communityRoutes)do local r=self.DB.communityRoutes[i];if type(r.steps)~="table"then r.steps={}end;while table.getn(r.steps)>self.MAX_STEPS do table.remove(r.steps)end end
end
function HC:MakeRouteId()
 self.DB.counter=(tonumber(self.DB.counter)or 0)+1;local name=string.gsub(UnitName("player")or"player","[^%w]","");return string.sub(name,1,10).."-"..tostring(self:Now()).."-"..tostring(self.DB.counter)
end
function HC:GetRoute(id)local i;for i=1,table.getn(self.DB.routes)do if self.DB.routes[i].id==id then return self.DB.routes[i],i end end;return nil,nil end
function HC:GetCommunityRoute(author,id)local i;for i=1,table.getn(self.DB.communityRoutes)do local r=self.DB.communityRoutes[i];if r.id==id and string.lower(r.author or"")==string.lower(author or"")then return r,i end end;return nil,nil end
function HC:GetSelectedRoute()return self:GetRoute(self.State.routeId)end
function HC:SelectRoute(id)
 local route=self:GetRoute(id);if not route then return nil end;self.State.routeId=id;self.State.stepIndex=1;self.State.stepOffset=0;local challenge,index=self:GetChallenge(route.challengeId);self.State.challengeIndex=index or 1;local i;for i=1,table.getn(self.Factions)do if self.Factions[i]==route.faction then self.State.factionIndex=i end end;for i=1,table.getn(self.Classes)do if self.Classes[i]==route.className then self.State.classIndex=i end end;if self.Frames and self.Frames.my then self.Frames.my.loadedRouteId=nil end;if self.RefreshUI then self:RefreshUI()end;return route
end
function HC:CreateRoute(name,challengeId)
 if table.getn(self.DB.routes)>=self.MAX_ROUTES then self:Print("route limit ("..self.MAX_ROUTES..") reached.");return nil end;name=self:Trim(name,48);if name==""then name="New leveling route"end;if not self:IsValidChallenge(challengeId)then challengeId="STANDARD"end
 local _,className=UnitClass("player");local route={id=self:MakeRouteId(),name=name,author=self:Trim(UnitName("player"),48),challengeId=challengeId,faction="Both",className="Any",minLevel=tonumber(UnitLevel("player"))or 1,maxLevel=60,description="",revision=1,createdAt=self:Now(),updatedAt=self:Now(),steps={}}
 table.insert(self.DB.routes,1,route);self.State.routeId=route.id;self.State.stepIndex=1;self.State.routeOffset=0;self.State.stepOffset=0;self:Print("route created: "..route.name..".");if self.RefreshUI then self:RefreshUI()end;return route
end
function HC:TouchRoute(route)route.revision=(tonumber(route.revision)or 0)+1;route.updatedAt=self:Now();route.dirty=1 end
function HC:UpdateRoute(route,name,challengeId,faction,className,minLevel,maxLevel,description)
 if not route then return nil end;name=self:Trim(name,48);if name~=""then route.name=name end;if self:IsValidChallenge(challengeId)then route.challengeId=challengeId end;if self:IsValidFaction(faction)then route.faction=faction end;if self:IsValidClass(className)then route.className=className end
 minLevel=tonumber(minLevel)or route.minLevel or 1;maxLevel=tonumber(maxLevel)or route.maxLevel or 60;if minLevel<1 then minLevel=1 end;if maxLevel>60 then maxLevel=60 end;if maxLevel<minLevel then maxLevel=minLevel end;route.minLevel=minLevel;route.maxLevel=maxLevel;route.description=self:Trim(description,120);self:TouchRoute(route);if self.RefreshUI then self:RefreshUI()end;return route
end
function HC:AddStep(route,stepType,title,note,capture,minLevel,maxLevel)
 if not route then self:Print("create or select a route first.");return nil end;if table.getn(route.steps)>=self.MAX_STEPS then self:Print("step limit ("..self.MAX_STEPS..") reached.");return nil end;if not self:IsValidStepType(stepType)then stepType="Note"end;title=self:Trim(title,48);if title==""then title=stepType.." step"end;local zone,sub=self:GetLocation();local x,y=nil,nil;if capture then x,y=self:GetCoordinates()end;minLevel=tonumber(minLevel)or tonumber(UnitLevel("player"))or 1;maxLevel=tonumber(maxLevel)or minLevel;if minLevel<1 then minLevel=1 end;if maxLevel>255 then maxLevel=255 end;if maxLevel<minLevel then maxLevel=minLevel end
 local step={type=stepType,title=title,note=self:Trim(note,80),zone=zone,subzone=sub,x=x,y=y,minLevel=minLevel,maxLevel=maxLevel,createdAt=self:Now()};table.insert(route.steps,step);self.State.stepIndex=table.getn(route.steps);self.State.stepOffset=self.State.stepIndex-7;if self.State.stepOffset<0 then self.State.stepOffset=0 end;self:TouchRoute(route);if self.RefreshUI then self:RefreshUI()end;return step
end
function HC:RemoveStep(route,index)
 if not route or not route.steps[index]then return end;table.remove(route.steps,index);if self.State.stepIndex>table.getn(route.steps)then self.State.stepIndex=table.getn(route.steps)end;if self.State.stepIndex<1 then self.State.stepIndex=1 end;self:TouchRoute(route);if self.RefreshUI then self:RefreshUI()end
end
function HC:MoveStep(route,index,direction)
 if not route then return end;local target=index+direction;if not route.steps[index]or target<1 or target>table.getn(route.steps)then return end;local step=route.steps[index];route.steps[index]=route.steps[target];route.steps[target]=step;self.State.stepIndex=target;if target<=self.State.stepOffset then self.State.stepOffset=target-1 elseif target>self.State.stepOffset+7 then self.State.stepOffset=target-7 end;self:TouchRoute(route);if self.RefreshUI then self:RefreshUI()end
end
function HC:DeleteSelectedRoute()
 local route,index=self:GetSelectedRoute();if not route then return end;local now=GetTime();if self.deleteConfirmId~=route.id or now-(self.deleteConfirmAt or 0)>6 then self.deleteConfirmId=route.id;self.deleteConfirmAt=now;self:Print("click Delete again within 6 seconds to remove '"..route.name.."'.");return end;table.remove(self.DB.routes,index);self.deleteConfirmId=nil;self.State.routeId=self.DB.routes[1]and self.DB.routes[1].id or nil;self.State.stepIndex=1;self:Print("route deleted.");if self.RefreshUI then self:RefreshUI()end
end
function HC:CopyCommunityRoute(route)
 if not route then return nil end;if table.getn(self.DB.routes)>=self.MAX_ROUTES then self:Print("route limit reached.");return nil end;local copy={id=self:MakeRouteId(),name=self:Trim(route.name.." (copy)",48),author=self:Trim(UnitName("player"),48),challengeId=route.challengeId,faction=route.faction,className=route.className,minLevel=route.minLevel,maxLevel=route.maxLevel,description=route.description,revision=1,createdAt=self:Now(),updatedAt=self:Now(),steps={}};local i;for i=1,table.getn(route.steps or{})do local step={};local k,v;for k,v in pairs(route.steps[i])do step[k]=v end;table.insert(copy.steps,step)end;table.insert(self.DB.routes,1,copy);self.State.routeId=copy.id;self.State.tab="My Routes";self:Print("community route copied to My Routes.");if self.RefreshUI then self:RefreshUI()end;return copy
end
function HC:SavePosition(frame,key)local p,rel,rp,x,y=frame:GetPoint();self.DB.settings[key or"position"]={point=p or"CENTER",relPoint=rp or"CENTER",x=x or 0,y=y or 0}end
function HC:Print(v)if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(self.COLORED_NAME..": "..tostring(v))end end
function HC:OnEvent(eventName,one,two,nine)
 if eventName=="VARIABLES_LOADED"then self:InitializeDB();self:InitializeNetwork();self:RestoreUISettings()
 elseif eventName=="PLAYER_ENTERING_WORLD"then if not self.loaded then self.loaded=1;self:Print("loaded. Build routes with |cffffffff/hcc|r; community network is OFF by default.")end;if self.DB.settings.networkEnabled then self:JoinNetwork()end;self:RefreshGuide()
 elseif eventName=="PLAYER_TARGET_CHANGED"or eventName=="PLAYER_LEVEL_UP"or eventName=="ZONE_CHANGED"or eventName=="ZONE_CHANGED_NEW_AREA"then self:RefreshGuide()
 elseif eventName=="CHAT_MSG_CHANNEL"then self:NetworkChat(one,two,nine)
 elseif eventName=="CHAT_MSG_CHANNEL_NOTICE"then self:NetworkNotice(one,nine)end
end
