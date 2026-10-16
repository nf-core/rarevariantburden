#' Use population control and assume a dominant model
#' Note that the disease risk with the wild type gene is only used to calculate
#' implied penetrance, disease risk overall. It will not influence the power

#' @param rr the relative risk of the mutated gene
#' @param mutationCarrierFreq the pathogenic mutation carrier frequency in the 
#'           population
#' @param diseaseInWildType the disease risk with the wild type gene
#' @param nCaseSize a vector of case size to calculate power for
#' @param nControlSize a vector of control size to calculate power for, can be very large as we are using population control
#' @param nReplication the number of replicates in the simulation to estimate power
#' @param thresholds a vector of p value thresholds to calculate power for
#' @param plot whether to plot the power curve

#' @return
#' powerTable: the power table

#' @export
burdenPower = function(rr = 5, 
                       mutationCarrierFreq = 0.0025,
                       diseaseInWildType = 0.1, 
                       nCaseSize = c(200, 600, 1200, 2000),
                       nControlSize = c(1e3, 2e3, 5e3, 1e4, 2e4, 5e4,
                                        1e5, 2e5, 5e5, 1e6, 1e7, 1e8),
                       nReplication = 1e3, 
                       thresholds = c(2.5e-6, 5e-2),
                       plot = T) {  
  probInCases = mutationCarrierFreq / 
    (mutationCarrierFreq + (1 - mutationCarrierFreq) / rr)
  
  penatrance = rr * diseaseInWildType
  prevalence = penatrance * mutationCarrierFreq + 
    diseaseInWildType * (1 - mutationCarrierFreq)
  
  print("#### parameters deciding the power ####")
  print(paste("Relative risk:", rr))
  print(paste("Pathogenic mutation carrier frequency in the populatoin:", 
              mutationCarrierFreq))
  print("#### Implied other parameters ####")
  print(paste("If the disease risk with the wild type gene is", 
                diseaseInWildType))
  print(paste("Implied penatrance:", penatrance))
  print(paste("Implied disease risk overall", prevalence))
  
  set.seed(1234)
  
  powerAll = list()
  for (l in 1:length(nCaseSize)) {
    nCase = nCaseSize[l]
    power = matrix(NA, length(nControlSize), length(thresholds))
    pvalues = matrix(NA, nReplication, length(nControlSize))
    for (j in 1:nReplication) {
      nMutationInCase = rbinom(n = 1, size = nCase, p = probInCases)
      nRefInCase = nCase - nMutationInCase
      for (k in 1:length(nControlSize)) {
        controlSize = nControlSize[k]
        nMutationInControl = rbinom(n = 1, size = controlSize,
                                    p = mutationCarrierFreq)
        nRefInControl = controlSize - nMutationInControl
        pvalue = fisher.test(
          cbind(c(nMutationInCase, nRefInCase),
                c(nMutationInControl, nRefInControl)))$p.value
        pvalues[j, k] = pvalue
      }
    }
    for (k in 1:length(nControlSize)) {
      for (i in 1:length(thresholds)) {
        threshold = thresholds[i]
        power[k, i] = mean(pvalues[, k] < threshold)
      }
    }
    colnames(power) = thresholds
    print(cbind(nCase, nControlSize, round(power, digits = 2)))
    powerAll[[l]] = power
  }
  
  # save the power result
  m = 1
  powerTable = matrix(NA, 
          length(nCaseSize) * length(nControlSize) * length(thresholds), 4)
  colnames(powerTable) = c("nCase", "nControl", "threshold", "power")
  for (i in 1:length(thresholds)) {
    threshold = thresholds[i]
    for (l in 1:length(nCaseSize)) {
      for (k in 1:length(nControlSize)) {
        n1 = nCaseSize[l]
        n0 = nControlSize[k]
        value = powerAll[[l]][k, i]
        powerTable[m, ] = c(n1, n0, threshold, value)
        m = m + 1
      }
    }
  }
  
  if (plot) {
    # in a single plot, but uses only 2.5e-6
    colors = c("red", "blue", "green", "cyan", "darkblue", "darkgreen")
    ylab = "power"
    xlab = "control (unit: 1000)"
    labels = nControlSize / 1e3
    for (i in 1:length(nCaseSize)) {
      plot(x = nControlSize,
           powerAll[[i]][, 1], type = c("b"), pch=1, 
           log = "x", lwd = 1, xaxt = "n", yaxt = "n",
           ylim = c(0, 1), xlim = range(nControlSize),
           xlab = xlab, ylab = ylab, 
           # cex = 0.5, cex.axis = 0.5, cex.lab = 0.5
           col = colors[i]) 
      ylab = ""
      xlab = ""
      par(new = T)
    }
    axis(1, at = nControlSize, labels = labels, cex.axis = 0.75)
    axis(2, at = seq(0.2, 1.0, 0.2), labels = seq(0.2, 1.0, 0.2), cex.axis = 0.75)
    abline(v = c(125748, 730947), col = c("orange", "purple"), lty = "dashed")
    legend("topleft", legend = paste("case:", c(nCaseSize)), col=colors, pch=1, 
           lwd = 1,
           bg = "transparent",
           bty = "n")
    abline(h = seq(0.1, 1, 0.1), col = "gray", lty = 2)
  }
  
  return(powerTable)
}

