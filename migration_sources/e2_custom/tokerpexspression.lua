e2function string entity:shipmentContents()
	if (!validEntity(this) or this:GetClass() != "spawned_shipment") then return "" end
	return CustomShipments[this.dt.contents]["name"]
end

e2function number entity:shipmentAmount()
	if (!validEntity(this) or this:GetClass() != "spawned_shipment") then return -1 end
	return this.dt.count
end

e2function number entity:moneyAmount()
	if (!validEntity(this)) then return -1 end
	if this:GetClass()=="spawned_money" then
		return this.Amount
	else
		return -1
	end
end
 