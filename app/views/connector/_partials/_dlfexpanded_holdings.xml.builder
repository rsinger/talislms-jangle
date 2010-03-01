xml.dlf :holdings do | holdings |
  holdings.dlf :holdingset do | hset |
    hset.dlf :holdingsrec do | rec |
      rec << entity.to_marcxml.to_s
    end
  end
end