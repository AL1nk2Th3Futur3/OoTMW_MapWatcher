function createDotHolder(xy, key){
  var area = $(`<div id="area-${key}" class="area"></div>`)
  var dot = $(`<div class="dot"></div>`)
  var playerNames = $(`<div class="playerNames"></div>`)
  area.append(dot)
  area.append(playerNames)
  area.css('top', `${xy[0]}px`)
  area.css('left', `${xy[1]}px`)
  $('.overworld').append(area)
}

function drawPlayerDot(Player, id) {
  var playerName = $(`<span id="${id}" class="playerName">${Player['Username']}</span>`)
  playerName.attr('colour', Player['Colour'])
  $(`#area-${Player['Location']} .playerNames`).append(playerName)
  $(`#area-${Player['Location']}`).css('visibility', 'visible')
  if ($(`#area-${Player['Location']} .playerNames`).children().length == 1) {
    $(`#area-${Player['Location']} .dot`).css('background-color', Player['Colour'])
  } else {
    $(`#area-${Player['Location']} .dot`).css('background-color', "#FFFFFF")
  }
}

function remPlayerDot(Player, id) {
  var playerName = $(`#${id}`)
  var parentArea = playerName.parent().parent()
  playerName.remove()
  if (parentArea.children('.playerNames').children().length == 0) {
    parentArea.css('visibility', 'hidden')
  }
  if (parentArea.children('.playerNames').children().length == 1) {
    parentArea.children('.dot').css('background-color', parentArea.children('.playerNames').children().attr('colour'))
  }
}

function movePlayerDot(data) {
  var area = $(`<div class="area"></div>`)
  var dot = $(`<div class="dot"></div>`)
  dot.css('background-color', data['Colour'])
  var playerName = $(`<span class="playerName">${data['Username']}</span>`)
  playerName.attr('colour', data['Colour'])
  area.append(dot)
  area.append(playerName)
  var parentArea = $(`#${data['Id']}`).parent().parent()
  var x = parentArea.css('left')
  var y = parentArea.css('top')
  area.css('top', `${y}`)
  area.css('left', `${x}`)
  area.css('visibility', 'visible')
  $(`#${data['Id']}`).remove()
  if (parentArea.children('.playerNames').children().length == 0) {
    parentArea.css('visibility', 'hidden')
  }
  if (parentArea.children('.playerNames').children().length == 1) {
    parentArea.children('.dot').css('background-color', parentArea.children('.playerNames').children().attr('colour'))
  }
  $('.overworld').append(area)
  area.velocity(
    {
    'top': LOCATIONS[data['Location']][0],
    'left': LOCATIONS[data['Location']][1]
    },
    {
      'duration': 1500,
      'easing': 'ease-in-out',
      'complete': function () {
        area.remove()
        playerName.attr('id', data['Id'])
        $(`#area-${data['Location']} .playerNames`).append(playerName)
        $(`#area-${data['Location']}`).css('visibility', 'visible')
        if ($(`#area-${data['Location']} .playerNames`).children().length == 1) {
          $(`#area-${data['Location']} .dot`).css('background-color', data['Colour'])
        } else {
          $(`#area-${data['Location']} .dot`).css('background-color', "#FFFFFF")
        }
      }
    }
  )
}

function remInvContainer(Player) {
  $(`#${Player['Id']}-inv`).remove()
}

function drawInvContainer(Player) {
  // Container and name
  var playerContainer = $(`<div id="${Player['Id']}-inv" class="player-invetory"></div>`)
  playerContainer.css('background-color', `${Player['Colour']}77`)
  var playerName = $(`<div class="player-name"><span>${Player['Username']}</span></div>`)
  playerContainer.append(playerName)

  // Items and equipment
  var iconHolder = $('<div class="icon-holder"></div>')
  var itemsIcons = $('<div class="items-icons"></div>')
  var equipmentIcons = $('<div class="equipment-icons"></div>')
  var upgradeIcons = $('<div class="upgrade-icons"></div>')
  equipmentIcons.append(upgradeIcons)
  iconHolder.append(itemsIcons, equipmentIcons)
  playerContainer.append(iconHolder)

  // Songs and medals
  var iconHolder = $('<div class="icon-holder"></div>')
  var songIcons = $('<div class="song-icons"></div>')
  var bossRewardIcons = $('<div class="boss-reward-icons"></div>')
  var medalIcons = $('<div class="medal-icons"></div>')
  var stoneIcons = $('<div class="stone-icons"></div>')
  bossRewardIcons.append(medalIcons, stoneIcons)
  iconHolder.append(songIcons, bossRewardIcons)
  playerContainer.append(iconHolder)

  // Hearts, rupees, skulls
  var iconHolder = $('<div class="icon-holder"></div>')
  iconHolder.css('justify-content', 'flex-start')
  var heartHolder = $('<div class="heart-icons"></div>')
  var rupeeHolder = $('<div class="rupees"></div>')
  var iconImg = $('<img src="/images/icons/132.png" class="icon">')
  rupeeHolder.append(iconImg, $('<span>000</span>'))
  var skulltulaHolder = $('<div class="skulltulas"></div>')
  var iconImg = $('<img src="/images/icons/113.png" class="icon">')
  skulltulaHolder.append(iconImg, $('<span>00</span>'))
  var cardAndStoneHolder = $('<div class="card-and-stone-holder"></div>')
  iconHolder.append(heartHolder, rupeeHolder, skulltulaHolder, cardAndStoneHolder)
  playerContainer.append(iconHolder)

  $('.players').append(playerContainer)
}

function drawPlayerItems(Player){
  var playerItems = $(`#${Player['Id']}-inv`).children('.icon-holder').children('.items-icons')
  playerItems.children('.icon').remove()
  for (var i = 0; i < Player['Items'].length; i++) {
    if (Player['Items'][i] == 255) {
      playerItems.append($(`<img class="icon">`))
      continue
    }
    playerItems.append($(`<img src="/images/icons/${Player['Items'][i]}.png" class="icon">`))
  }
}

function drawPlayerEquipment(Player) {
  var playerItems = $(`#${Player['Id']}-inv`).children('.icon-holder').children('.equipment-icons')
  playerItems.children('.icon').remove()
  for (var i = 0; i < Player['Equipment'].length; i++) {
    if (Player['Equipment'][i] == 255) {
      playerItems.append($(`<img class="icon">`))
      continue
    }
    playerItems.append($(`<img src="/images/icons/${Player['Equipment'][i]}.png" class="icon">`))
  }
}

function drawPlayerUpgrades(Player) {
  var playerItems = $(`#${Player['Id']}-inv`).children('.icon-holder').children('.equipment-icons').children('.upgrade-icons')
  playerItems.children('.icon').remove()
  for (var i = 0; i < Player['Upgrades'].length; i++) {
    if (Player['Upgrades'][i] == 255) {
      playerItems.append($(`<img class="icon">`))
      continue
    }
    playerItems.append($(`<img src="/images/icons/${Player['Upgrades'][i]}.png" class="icon">`))
  }
}

function drawPlayerQuestItems(Player) {
  var songIcons = $(`#${Player['Id']}-inv`).children('.icon-holder').children('.song-icons')
  var medalIcons = $(`#${Player['Id']}-inv`).children('.icon-holder').children('.boss-reward-icons').children('.medal-icons')
  var stoneIcons = $(`#${Player['Id']}-inv`).children('.icon-holder').children('.boss-reward-icons').children('.stone-icons')
  var stoneAndCardIcons = $(`#${Player['Id']}-inv`).children('.icon-holder').children('.card-and-stone-holder')
  songIcons.children('.icon').remove()
  medalIcons.children('.icon').remove()
  stoneIcons.children('.icon').remove()
  stoneAndCardIcons.children('.icon').remove()
  for (var i = 0; i < 12; i++) {
    if (Player['QuestItems'][i] == 255) {
      songIcons.append($(`<img class="icon">`))
      continue
    }
    songIcons.append($(`<img src="/images/icons/${Player['QuestItems'][i]}.png" class="icon">`))
  }
  for (var i = 12; i < 18; i++) {
    if (Player['QuestItems'][i] == 255) {
      medalIcons.append($(`<img class="icon">`))
      continue
    }
    medalIcons.append($(`<img src="/images/icons/${Player['QuestItems'][i]}.png" class="icon">`))
  }
  for (var i = 18; i < 21; i++) {
    if (Player['QuestItems'][i] == 255) {
      stoneIcons.append($(`<img class="icon">`))
      continue
    }
    stoneIcons.append($(`<img src="/images/icons/${Player['QuestItems'][i]}.png" class="icon">`))
  }
  for (var i = 21; i < 23; i++) {
    if (Player['QuestItems'][i] == 255) {
      stoneAndCardIcons.append($(`<img class="icon">`))
      continue
    }
    stoneAndCardIcons.append($(`<img src="/images/icons/${Player['QuestItems'][i]}.png" class="icon">`))
  }
}

function drawPlayerMaxHearts(Player) {
  var playerItems = $(`#${Player['Id']}-inv`).children('.icon-holder').children('.heart-icons')
  playerItems.children('.icon').remove()
  for (var i = 0; i < Player['MaxHearts']; i++) {
    playerItems.append($(`<img src="/images/icons/Heart.png" class="icon">`))
  }
}

function drawPlayerRupees(Player) {
  var playerItems = $(`#${Player['Id']}-inv`).children('.icon-holder').children('.rupees').children('span')
  if (Player['Rupees'] < 10) {
    playerItems.html(`00${Player['Rupees']}`)
  } else if (Player['Rupees'] < 100) {
    playerItems.html(`0${Player['Rupees']}`)
  } else {
    playerItems.html(`${Player['Rupees']}`)
  }
}

function drawPlayerSkulltulas(Player) {
  var playerItems = $(`#${Player['Id']}-inv`).children('.icon-holder').children('.skulltulas').children('span')
  if (Player['Skulltulas'] < 10) {
    playerItems.html(`0${Player['Skulltulas']}`)
  } else {
    playerItems.html(`${Player['Skulltulas']}`)
  }
}
