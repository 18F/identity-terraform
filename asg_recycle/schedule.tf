locals {
  rotation_schedules = {
    "nozero_norecycle" = {
      recycle_up    = []
      recycle_down  = []
      autozero_up   = []
      autozero_down = []
    }
    "nozero_normal" = {
      recycle_up    = ["0 5,11,17,23 * * *"]
      recycle_down  = ["15 5,11,17,23 * * *"]
      autozero_up   = []
      autozero_down = []
    }
    "nozero_business" = {
      recycle_up    = ["0 17 * * 1-5"]
      recycle_down  = ["15 17 * * 1-5"]
      autozero_up   = []
      autozero_down = []
    }
    "dailyzero_norecycle" = {
      recycle_up    = []
      recycle_down  = []
      autozero_up   = ["0 5 * * 1-5"]
      autozero_down = ["0 17 * * 1-5"]
    }
    "dailyzero_normal" = {
      recycle_up    = ["0 11 * * 1-5"]
      recycle_down  = ["15 11 * * 1-5"]
      autozero_up   = ["0 5 * * 1-5"]
      autozero_down = ["0 17 * * 1-5"]
    }
    "dailyzero_business" = {
      recycle_up    = []
      recycle_down  = []
      autozero_up   = ["0 5 * * 1-5"]
      autozero_down = ["0 17 * * 1-5"]
    }
    "nightlyzero_norecycle" = {
      recycle_up    = []
      recycle_down  = []
      autozero_up   = ["0 5 * * 1-5"]
      autozero_down = ["0 21 * * 1-5"]
    }
    "nightlyzero_normal" = {
      recycle_up    = ["0 11,17 * * 1-5"]
      recycle_down  = ["15 11,17 * * 1-5"]
      autozero_up   = ["0 5 * * 1-5"]
      autozero_down = ["0 21 * * 1-5"]
    }
    "nightlyzero_business" = {
      recycle_up    = ["0 17 * * 1-5"]
      recycle_down  = ["15 17 * * 1-5"]
      autozero_up   = ["0 5 * * 1-5"]
      autozero_down = ["0 21 * * 1-5"]
    }
    "weeklyzero_norecycle" = {
      recycle_up    = []
      recycle_down  = []
      autozero_up   = ["0 5 * * 1"]
      autozero_down = ["0 17 * * 5"]
    }
    "weeklyzero_normal" = {
      recycle_up = [
        "0 11,17,23 * * 1",
        "0 5,11,17,23 * * 2-4",
        "0 5,11 * * 5",
      ]
      recycle_down = [
        "15 11,17,23 * * 1",
        "15 5,11,17,23 * * 2-4",
        "15 5,11 * * 5",
      ]
      autozero_up   = ["0 5 * * 1"]
      autozero_down = ["0 17 * * 5"]
    }
    "weeklyzero_business" = {
      recycle_up    = ["0 17 * * 1-4"]
      recycle_down  = ["15 17 * * 1-4"]
      autozero_up   = ["0 5 * * 1"]
      autozero_down = ["0 17 * * 5"]
    }
  }
}
