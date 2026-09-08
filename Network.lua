local HC=HCChallenger
HC.PROTOCOL="HCS1"
HC.CHANNEL="HCSafety"
HC.MAX_MESSAGE=240
HC.SEND_DELAY=1.25
HC.CATALOG_TTL=900

local function Split(value,delimiter)
 local fields={};local part;for part in string.gfind((value or"")..delimiter,"(.-)"..delimiter)do table.insert(fields,part)end;return fields
end
function HC:Escape(value)
 value=tostring(value or"");value=string.gsub(value,"%%","%%25");value=string.gsub(value,"|","%%7C");value=string.gsub(value,"~","%%7E");value=string.gsub(value,"\r","%%0D");value=string.gsub(value,"\n","%%0A");return value
end
function HC:Unescape(value)
 value=tostring(value or"");value=string.gsub(value,"%%0A"," ");value=string.gsub(value,"%%0D"," ");value=string.gsub(value,"%%7E","~");value=string.gsub(value,"%%7C","|");value=string.gsub(value,"%%25","%%");return value
end
function HC:NameKey(name)
 name=string.lower(self:Trim(name,64));local _,_,short=string.find(name,"^([^%-]+)");return short or name
end
function HC:ValidId(id)return id and string.len(id)>=3 and string.len(id)<=48 and not string.find(id,"[^%w%-%_]")end
function HC:InitializeNetwork()
 self.Network={state="OFFLINE",queue={},seen={},receive={},counter=0,lastSend=0,nextClean=GetTime()+10,nextAdvertise=GetTime()+60,lastServed={}}
end
function HC:HideChannel()
 local i;for i=1,7 do local frame=getglobal("ChatFrame"..i);if frame and ChatFrame_RemoveChannel then ChatFrame_RemoveChannel(frame,self.CHANNEL)end end
end
function HC:NetworkStatus()
 if not self.DB or not self.DB.settings.networkEnabled then return"Community: OFF (local routes still work)"end;local state=self.Network and self.Network.state or"OFFLINE";if state=="ONLINE"then return"Community: HCSafety joined"elseif state=="JOINING"then return"Community: joining HCSafety"elseif state=="ERROR"then return"Community: channel unavailable"end;return"Community: offline"
end
function HC:JoinNetwork()
 if not self.DB.settings.networkEnabled then return end;local id=GetChannelName(self.CHANNEL);if id and id>0 then self.Network.state="ONLINE";self:HideChannel();self:AdvertisePublishedRoutes();if self.RefreshUI then self:RefreshUI()end;return end;self.Network.state="JOINING";JoinChannelByName(self.CHANNEL,nil,DEFAULT_CHAT_FRAME:GetID());if self.RefreshUI then self:RefreshUI()end
end
function HC:StopNetwork()
 if not self.Network then return end;self.Network.queue={};self.Network.state="OFFLINE";self:Print("community traffic disabled. The shared HCSafety channel is left intact for other suite addons.");if self.RefreshUI then self:RefreshUI()end
end
function HC:MakeMessageId()
 self.Network.counter=self.Network.counter+1;local name=string.gsub(UnitName("player")or"p","[^%w]","");return string.sub(name,1,10).."-"..tostring(math.floor(GetTime())).."-"..tostring(self.Network.counter)
end
function HC:Queue(typeName,payload)
 if not self.DB.settings.networkEnabled then return nil end;local id=self:MakeMessageId();local message=self.PROTOCOL.."|"..self.MODULE.."|"..typeName.."|"..id.."|"..payload;if string.len(message)>self.MAX_MESSAGE then self:Print("a community message exceeded 240 bytes and was skipped.");return nil end;if table.getn(self.Network.queue)>=200 then self:Print("community send queue is full; try again later.");return nil end;table.insert(self.Network.queue,message);return 1
end
function HC:AdvertisementPayload(route)
 local age=self:Now()-(route.updatedAt or self:Now());if age<0 then age=0 end;if age>2592000 then age=2592000 end
 return tostring(age).."~"..self:Escape(route.id).."~"..tostring(route.revision or 1).."~"..self:Escape(self:Trim(route.name,48)).."~"..self:Escape(route.challengeId).."~"..self:Escape(route.faction).."~"..self:Escape(route.className).."~"..tostring(route.minLevel or 1).."~"..tostring(route.maxLevel or 60).."~"..tostring(table.getn(route.steps or{})).."~"..self:Escape(self:Trim(route.description,48))
end
function HC:PublishRoute(route)
 if not route then self:Print("select a route first.");return nil end;if table.getn(route.steps)==0 then self:Print("add at least one step before publishing.");return nil end;if not self.DB.settings.networkEnabled then self:Print("community network is OFF. Enable it before publishing.");return nil end
 route.publishedRevision=route.revision;route.publishedAt=self:Now();route.dirty=nil;local ok=self:Queue("ADV",self:AdvertisementPayload(route));if ok then self:Print("route advertised. Content is sent only when another player clicks Download.")end;if self.RefreshUI then self:RefreshUI()end;return ok
end
function HC:AdvertisePublishedRoutes()
 if not self.DB or not self.DB.settings.networkEnabled then return end;local i;for i=1,table.getn(self.DB.routes)do local route=self.DB.routes[i];if route.publishedRevision then self:Queue("ADV",self:AdvertisementPayload(route))end end
end
function HC:GetCatalogList()
 local list={};local now=GetTime();local key,item;for key,item in pairs(self.Catalog)do if now-(item.lastSeen or now)<=self.CATALOG_TTL then table.insert(list,item)end end
 table.sort(list,function(a,b)local ac=a.challengeId=="TRIAL_HEROISM"and 0 or 1;local bc=b.challengeId=="TRIAL_HEROISM"and 0 or 1;if ac~=bc then return ac<bc end;if a.challengeId~=b.challengeId then return(a.challengeId or"")<(b.challengeId or"")end;return(a.name or"")<(b.name or"")end);return list
end
function HC:GetSelectedCatalog()
 local list=self:GetCatalogList();local i;for i=1,table.getn(list)do if list[i].key==self.State.communityKey then return list[i]end end;return nil
end
function HC:RequestRoute(item)
 if not item then self:Print("select a community route first.");return nil end;if not self.DB.settings.networkEnabled then self:Print("community network is OFF.");return nil end;local key=self:NameKey(item.author).."~"..item.id;self.PendingDownloads[key]={expires=GetTime()+240,revision=item.revision};local payload="0~"..self:Escape(item.author).."~"..self:Escape(item.id).."~"..tostring(item.revision or 1);local ok=self:Queue("REQ",payload);if ok then self:Print("download requested from "..item.author..". Keep both players online while steps arrive.")end;return ok
end
function HC:QueueRouteTransfer(route,target)
 if table.getn(self.Network.queue)>50 then return nil end;local targetField=self:Escape(self:Trim(target,48));local base="0~"..targetField.."~"..self:Escape(route.id).."~"..tostring(route.revision or 1).."~"
 local header=base..self:Escape(self:Trim(route.name,48)).."~"..self:Escape(route.challengeId).."~"..self:Escape(route.faction).."~"..self:Escape(route.className).."~"..tostring(route.minLevel or 1).."~"..tostring(route.maxLevel or 60).."~"..tostring(table.getn(route.steps)).."~"..self:Escape(self:Trim(route.description,48));if not self:Queue("HDR",header)then return nil end
 local i;for i=1,table.getn(route.steps)do local step=route.steps[i];local first=base..tostring(i).."~"..self:Escape(step.type).."~"..self:Escape(self:Trim(step.title,48)).."~"..self:Escape(self:Trim(step.zone,40)).."~"..(step.x and tostring(step.x)or"").."~"..(step.y and tostring(step.y)or"").."~"..tostring(step.minLevel or 1).."~"..tostring(step.maxLevel or step.minLevel or 1);local second=base..tostring(i).."~"..self:Escape(self:Trim(step.note,80)).."~"..self:Escape(self:Trim(step.subzone,40));if not self:Queue("ST1",first)or not self:Queue("ST2",second)then return nil end end
 self:Queue("END","0~"..targetField.."~"..self:Escape(route.id).."~"..tostring(route.revision or 1).."~"..tostring(table.getn(route.steps)));return 1
end
function HC:AllowedSender(sender)
 local key=self:NameKey(sender);if key==""then return nil end;local now=GetTime();local rate=self.Network.receive[key];if not rate or now-rate.started>10 then rate={started=now,count=0};self.Network.receive[key]=rate end;rate.count=rate.count+1;if rate.count>12 then return nil end;return 1
end
function HC:TargetIsMe(value)return self:NameKey(value)==self:NameKey(UnitName("player")or"")end
function HC:ParseAdvertisement(payload,sender)
 local f=Split(payload,"~");local age=tonumber(f[1]);local id=self:Unescape(f[2]);local revision=tonumber(f[3]);local challenge=self:Unescape(f[5]);local faction=self:Unescape(f[6]);local className=self:Unescape(f[7]);local minLevel=tonumber(f[8]);local maxLevel=tonumber(f[9]);local stepCount=tonumber(f[10]);if not age or age<0 or age>2592000 or not self:ValidId(id)or not revision or revision<1 or not self:IsValidChallenge(challenge)or not self:IsValidFaction(faction)or not self:IsValidClass(className)or not minLevel or minLevel<1 or minLevel>60 or not maxLevel or maxLevel<minLevel or maxLevel>60 or not stepCount or stepCount<1 or stepCount>self.MAX_STEPS then return nil end
 local key=self:NameKey(sender).."~"..id;local item={key=key,id=id,author=self:Trim(sender,48),revision=revision,name=self:Trim(self:Unescape(f[4]),48),challengeId=challenge,faction=faction,className=className,minLevel=minLevel,maxLevel=maxLevel,stepCount=stepCount,description=self:Trim(self:Unescape(f[11]),48),updatedAt=self:Now()-age,lastSeen=GetTime()};self.Catalog[key]=item;if not self.State.communityKey then self.State.communityKey=key end;return item
end
function HC:HandleRequest(payload,sender)
 local f=Split(payload,"~");if not self:TargetIsMe(self:Unescape(f[2]))then return end;local id=self:Unescape(f[3]);local revision=tonumber(f[4]);if not self:ValidId(id)or not revision then return end;local route=self:GetRoute(id);if not route or not route.publishedRevision or route.revision~=route.publishedRevision then return end;local key=self:NameKey(sender).."~"..id;local now=GetTime();if now-(self.Network.lastServed[key]or 0)<120 then return end;self.Network.lastServed[key]=now;if self:QueueRouteTransfer(route,sender)then self:Print("sending '"..route.name.."' to "..sender..".")end
end
function HC:HandleHeader(payload,sender)
 local f=Split(payload,"~");if not self:TargetIsMe(self:Unescape(f[2]))then return end;local id=self:Unescape(f[3]);local revision=tonumber(f[4]);local pendingKey=self:NameKey(sender).."~"..id;local pending=self.PendingDownloads[pendingKey];local challenge=self:Unescape(f[6]);local faction=self:Unescape(f[7]);local className=self:Unescape(f[8]);local minLevel=tonumber(f[9]);local maxLevel=tonumber(f[10]);local count=tonumber(f[11]);if not pending or pending.expires<GetTime()or not self:ValidId(id)or not revision or revision<pending.revision or not self:IsValidChallenge(challenge)or not self:IsValidFaction(faction)or not self:IsValidClass(className)or not minLevel or minLevel<1 or not maxLevel or maxLevel<minLevel or maxLevel>60 or not count or count<1 or count>self.MAX_STEPS then return end
 self.Transfers[pendingKey]={id=id,author=self:Trim(sender,48),revision=revision,name=self:Trim(self:Unescape(f[5]),48),challengeId=challenge,faction=faction,className=className,minLevel=minLevel,maxLevel=maxLevel,stepCount=count,description=self:Trim(self:Unescape(f[12]),48),steps={},started=GetTime()}
end
function HC:GetTransfer(payload,sender)
 local f=Split(payload,"~");if not self:TargetIsMe(self:Unescape(f[2]))then return nil,nil end;local id=self:Unescape(f[3]);local revision=tonumber(f[4]);local key=self:NameKey(sender).."~"..id;local transfer=self.Transfers[key];if not transfer or transfer.revision~=revision or GetTime()-transfer.started>240 then return nil,nil end;return transfer,f
end
function HC:HandleStepOne(payload,sender)
 local transfer,f=self:GetTransfer(payload,sender);if not transfer then return end;local index=tonumber(f[5]);local stepType=self:Unescape(f[6]);local x=tonumber(f[9]);local y=tonumber(f[10]);local minLevel=tonumber(f[11]);local maxLevel=tonumber(f[12]);if not index or index<1 or index>transfer.stepCount or not self:IsValidStepType(stepType)or not minLevel or minLevel<1 or not maxLevel or maxLevel<minLevel or maxLevel>255 then return end;if(x and(x<=0 or x>1))or(y and(y<=0 or y>1))or((x and not y)or(y and not x))then x=nil;y=nil end;local step=transfer.steps[index]or{};step.type=stepType;step.title=self:Trim(self:Unescape(f[7]),48);step.zone=self:Trim(self:Unescape(f[8]),40);step.x=x;step.y=y;step.minLevel=minLevel;step.maxLevel=maxLevel;transfer.steps[index]=step
end
function HC:HandleStepTwo(payload,sender)
 local transfer,f=self:GetTransfer(payload,sender);if not transfer then return end;local index=tonumber(f[5]);if not index or index<1 or index>transfer.stepCount then return end;local step=transfer.steps[index]or{};step.note=self:Trim(self:Unescape(f[6]),80);step.subzone=self:Trim(self:Unescape(f[7]),40);transfer.steps[index]=step
end
function HC:CompleteTransfer(payload,sender)
 local transfer,f=self:GetTransfer(payload,sender);if not transfer then return end;local count=tonumber(f[5]);if count~=transfer.stepCount then return end;local i;for i=1,count do if not transfer.steps[i]or not transfer.steps[i].type then return end;transfer.steps[i].note=transfer.steps[i].note or"";transfer.steps[i].subzone=transfer.steps[i].subzone or""end
 local existing,index=self:GetCommunityRoute(transfer.author,transfer.id);local route={id=transfer.id,author=transfer.author,revision=transfer.revision,name=transfer.name,challengeId=transfer.challengeId,faction=transfer.faction,className=transfer.className,minLevel=transfer.minLevel,maxLevel=transfer.maxLevel,description=transfer.description,steps=transfer.steps,downloadedAt=self:Now(),source="community"};if existing then self.DB.communityRoutes[index]=route else table.insert(self.DB.communityRoutes,1,route)end;while table.getn(self.DB.communityRoutes)>self.MAX_COMMUNITY_ROUTES do table.remove(self.DB.communityRoutes)end;local key=self:NameKey(sender).."~"..transfer.id;self.Transfers[key]=nil;self.PendingDownloads[key]=nil;self:Print("downloaded '"..route.name.."' with "..count.." steps from "..route.author..".");if self.RefreshUI then self:RefreshUI()end
end
function HC:HandleProtocol(message,sender)
 if type(message)~="string"or string.len(message)>self.MAX_MESSAGE or self:NameKey(sender)==self:NameKey(UnitName("player")or"")then return end;local p=Split(message,"|");if p[1]~=self.PROTOCOL or p[2]~=self.MODULE then return end;local typeName=p[3];local id=p[4];if not self:ValidId(id)or self.Network.seen[id]or not self:AllowedSender(sender)then return end;self.Network.seen[id]=GetTime();local payload=p[5]or""
 if typeName=="ADV"then self:ParseAdvertisement(payload,sender)
 elseif typeName=="REQ"then self:HandleRequest(payload,sender)
 elseif typeName=="HDR"then self:HandleHeader(payload,sender)
 elseif typeName=="ST1"then self:HandleStepOne(payload,sender)
 elseif typeName=="ST2"then self:HandleStepTwo(payload,sender)
 elseif typeName=="END"then self:CompleteTransfer(payload,sender)
 else return end;if self.RefreshUI then self:RefreshUI()end
end
function HC:NetworkChat(message,sender,channelName)
 if not self.DB.settings.networkEnabled then return end;if channelName and channelName~=""and string.upper(channelName)~=string.upper(self.CHANNEL)then return end;self:HandleProtocol(message,sender)
end
function HC:NetworkNotice(kind,channelName)
 if channelName and string.upper(channelName)==string.upper(self.CHANNEL)then if kind=="YOU_JOINED"then self.Network.state="ONLINE";self:HideChannel();self:AdvertisePublishedRoutes()elseif kind=="YOU_LEFT"then self.Network.state="ERROR"end;if self.RefreshUI then self:RefreshUI()end end
end
function HC:PruneNetwork()
 local now=GetTime();local id,at;for id,at in pairs(self.Network.seen)do if now-at>600 then self.Network.seen[id]=nil end end;local key,item;for key,item in pairs(self.Catalog)do if now-(item.lastSeen or now)>self.CATALOG_TTL then self.Catalog[key]=nil end end;for key,item in pairs(self.PendingDownloads)do if item.expires<now then self.PendingDownloads[key]=nil;self.Transfers[key]=nil end end
end
function HC:NetworkUpdate()
 if not self.Network then return end;local now=GetTime();if self.DB.settings.networkEnabled and table.getn(self.Network.queue)>0 and now-self.Network.lastSend>=self.SEND_DELAY then local channel=GetChannelName(self.CHANNEL);if channel and channel>0 then local message=self.Network.queue[1];table.remove(self.Network.queue,1);SendChatMessage(message,"CHANNEL",nil,channel);self.Network.lastSend=now;self.Network.state="ONLINE"elseif self.Network.state~="JOINING"then self:JoinNetwork()end end
 if now>=self.Network.nextAdvertise then self.Network.nextAdvertise=now+300+(math.random()*45);if self.DB.settings.networkEnabled then self:AdvertisePublishedRoutes()end end;if now>=self.Network.nextClean then self.Network.nextClean=now+10;self:PruneNetwork()end
end
