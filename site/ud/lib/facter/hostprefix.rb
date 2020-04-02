Facter.add(:hostprefix) do
  setcode do
    Facter.value(:hostname).sub(/-\S?$/, '')
  end
end
