local HC=HCChallenger

function HC:RouteKey(route,source)
 if source=="community"then return"community:"..self:NameKey(route.author)..":"..route.id end;return"local:"..route.id
end
function HC:GetRouteReference(reference)
 if not reference then return nil end;if reference.source=="community"then return self:GetCommunityRoute(reference.author,reference.id)end;return self:GetRoute(reference.id)
end
function HC:GetActiveReference()
 if not self.DB then return nil end;self.DB.active=self.DB.active or{};return self.DB.active[self:GetCharacterKey()]
end
function HC:GetActiveRoute()
 local reference=self:GetActiveReference();if not reference then return nil,nil end;return self:GetRouteReference(reference),reference
end
function HC:GetProgress(route,source)
 self.DB.progress[self:GetCharacterKey()]=self.DB.progress[self:GetCharacterKey()]or{};local key=self:RouteKey(route,source);local progress=self.DB.progress[self:GetCharacterKey()][key];if not progress then progress={step=1,completed={}};self.DB.progress[self:GetCharacterKey()][key]=progress end;if type(progress.completed)~="table"then progress.completed={}end;if progress.step<1 then progress.step=1 end;if progress.step>table.getn(route.steps)and table.getn(route.steps)>0 then progress.step=table.getn(route.steps)end;return progress
end
function HC:ActivateRoute(route,source)
 if not route or table.getn(route.steps or{})==0 then self:Print("the selected route has no steps.");return nil end;source=source=="community"and"community"or"local";self.DB.active=self.DB.active or{};self.DB.active[self:GetCharacterKey()]={source=source,id=route.id,author=route.author};self:GetProgress(route,source);self:Print("guide activated: "..route.name..".");if self.ShowGuide then self:ShowGuide()end;self:RefreshGuide();return 1
end
function HC:AdvanceGuide(markComplete)
 local route,reference=self:GetActiveRoute();if not route then return end;local progress=self:GetProgress(route,reference.source);if markComplete then progress.completed[progress.step]=1 end;if progress.step<table.getn(route.steps)then progress.step=progress.step+1 else self:Print("route complete: "..route.name..".")end;self:RefreshGuide()
end
function HC:PreviousGuide()
 local route,reference=self:GetActiveRoute();if not route then return end;local progress=self:GetProgress(route,reference.source);progress.step=progress.step-1;if progress.step<1 then progress.step=1 end;self:RefreshGuide()
end
function HC:GetTrialEligibility(route,step)
 if not route or route.challengeId~="TRIAL_HEROISM"then return nil,nil end;local playerLevel=tonumber(UnitLevel("player"))or 1;if playerLevel>=58 then return"Trial kill restriction ends at level 58 according to the pictured rules.","GREEN"end;if step and(step.type=="Quest"or step.type=="Turn in")then return"Quest experience is permitted. Kill XP still requires target level "..(playerLevel+3).."+.","GOLD"end
 if not UnitExists("target")then return"Trial check: target an enemy manually. Required level: "..(playerLevel+3).."+.","GOLD"end;local targetLevel=tonumber(UnitLevel("target"));if not targetLevel or targetLevel<0 then return"Trial check: target level is unknown (skull); verify manually.","GOLD"end;if UnitCanAttack and not UnitCanAttack("player","target")then return"Trial check: current target is not attackable.","RED"end;if targetLevel>=playerLevel+3 then return"ELIGIBLE KILL: target level "..targetLevel.." is at least "..(playerLevel+3)..".","GREEN"end;return"NO KILL XP: target level "..targetLevel.." is below required "..(playerLevel+3)..".","RED"
end
function HC:GetStepLocationText(step)
 local text=step.zone or"Unknown zone";if step.subzone and step.subzone~=""then text=text.." / "..step.subzone end;if step.x and step.y then text=text.."  ("..math.floor(step.x*100)..", "..math.floor(step.y*100)..")"end;return text
end
function HC:GetDistanceText(step)
 if not step or not step.x or not step.y then return"Zone-only step; no position was recorded."end;local zone=GetRealZoneText and GetRealZoneText()or"";if zone~=step.zone then return"Travel to "..step.zone.."."end;local x,y=self:GetCoordinates();if not x then return"Current coordinates unavailable."end;local dx=step.x-x;local dy=step.y-y;local distance=math.sqrt((dx*dx)+(dy*dy))*100;local horizontal=dx>0 and"E"or"W";local vertical=dy>0 and"S"or"N";if math.abs(dx)<.02 then horizontal=""end;if math.abs(dy)<.02 then vertical=""end;return"Approx. "..math.floor(distance).." map-points "..vertical..horizontal.."."end
function HC:RefreshGuide()
 if not self.Frames or not self.Frames.guide then return end;local frame=self.Frames.guide;local route,reference=self:GetActiveRoute();if not route then frame.route:SetText("No active route");frame.step:SetText("Choose a route in HC Challenger.");frame.location:SetText("");frame.note:SetText("");frame.challenge:SetText("");frame.distance:SetText("");return end;local progress=self:GetProgress(route,reference.source);local step=route.steps[progress.step];frame.route:SetText(route.name.."  |  "..self:GetChallengeName(route.challengeId));frame.counter:SetText("Step "..progress.step.." / "..table.getn(route.steps));if step then frame.step:SetText(string.upper(step.type)..": "..step.title);frame.location:SetText(self:GetStepLocationText(step));frame.note:SetText(step.note~=""and step.note or"No note for this step.");frame.distance:SetText(self:GetDistanceText(step));local trial,color=self:GetTrialEligibility(route,step);if trial then frame.challenge:SetText(trial);if color=="GREEN"then frame.challenge:SetTextColor(.3,1,.3)elseif color=="RED"then frame.challenge:SetTextColor(1,.25,.2)else frame.challenge:SetTextColor(1,.78,.25)end else local challenge=self:GetChallenge(route.challengeId);frame.challenge:SetText(challenge.advice or"");frame.challenge:SetTextColor(1,.78,.25)end end
end
