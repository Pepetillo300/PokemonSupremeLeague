module Settings
  EGGMOVESSWITCH  = 59
end
RELEARNABLEEGGMOVES = false

class Pokemon
  attr_writer :unlocked_relearner
  
  def unlocked_relearner
    return @unlocked_relearner ||= false
  end
  
  alias old_can_relearn_move? can_relearn_move? unless method_defined?(:old_can_relearn_move?)
  def can_relearn_move?
    return old_can_relearn_move? && get_relearnable_moves(self).size > 0
  end
end

MenuHandlers.add(:party_menu, :relearner, {
  "name"      => _INTL("Recuerda Movimientos"),
  "order"     => 65,
  "effect"    => proc { |screen, party, party_idx|
    pkmn = party[party_idx]
    if pkmn.egg?
      pbMessage(_INTL("No puedes usar el recuerda movimientos en un huevo."))
    elsif pkmn.shadowPokemon?
      pbMessage(_INTL("No puedes usar el recuerda movimientos en un pokemon oscuro."))
    elsif pkmn.unlocked_relearner
      if !pkmn.can_relearn_move?
        pbMessage(_INTL("No se pueden recordar movimientos."))
      else
        pbRelearnMoveScreen(party[party_idx])
      end
    else
      if $bag.has?(:HEARTSCALE)
        yes = pbConfirmMessage(
            _INTL("¿Quieres desbloquear el recuerda movimientos en este pokemon por una escama corazón?"))
        if yes
          pkmn.unlocked_relearner = true
          $bag.remove(:HEARTSCALE)
          pbMessage(_INTL("Ya puedes recordar movimientos a este pokemon."))
          pbRelearnMoveScreen(party[party_idx])
        end
      else
        pbMessage(_INTL("Puedes desbloquear el recuerda movimientos en este pokemon por una escama corazón."))
      end
    end
  }
})

class MoveRelearnerScreen
  def pbGetRelearnableMoves(pkmn)
    return get_relearnable_moves(pkmn)
  end
end

def get_relearnable_moves(pkmn)
  return [] if !pkmn || pkmn.egg? || pkmn.shadowPokemon?
  moves = []
  pkmn.getMoveList.each do |m|
    next if m[0] > pkmn.level || pkmn.hasMove?(m[1])
    moves.push(m[1]) if !moves.include?(m[1])
  end
  GameData::Species.get(pkmn.species).get_egg_moves.each do |m|
    next if pkmn.hasMove?(m)
    moves.push(m)
  end
  if $game_switches[Settings::EGGMOVESSWITCH] && pkmn.first_moves || RELEARNABLEEGGMOVES ==true && pkmn.first_moves
    tmoves = []
    pkmn.first_moves.each do |i|
      tmoves.push(i) if !moves.include?(i) && !pkmn.hasMove?(i)
    end
    moves = tmoves + moves   # List first moves before level-up moves
  end
  return moves | []   # remove duplicates
end