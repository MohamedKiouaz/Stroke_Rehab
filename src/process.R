ProcessData = function(data_) {
  library(pracma)

  print(paste("Processing data from", data_$filename))

  avg_filter = as.numeric(matrix(1/n, 1, n))

  A = apply(data_$raw, 1, function(X) norm(as.matrix(X)))
  data_$raw = cbind(data_$raw, A)
  colnames(data_$raw) = c("x", "y", "z", "norm")

  data_$avg = apply(data_$raw[1:3], 2, function(X) filter(X, avg_filter, method = "convolution", circular = TRUE))
  data_$avg = apply(data_$avg, 2, function(X) detrend(X, 'linear'))
  A = apply(data_$avg, 1, function(X) norm(as.matrix(X)))
  data_$avg = cbind(data_$avg, A)
  colnames(data_$avg) = c("x", "y", "z", "norm")

  data_ = Movement(data_)

  data_$period = median(tail(data_$null, length(data_$null) - 1) - head(data_$null, length(data_$null) - 1))

  data_$score = Score(data_)

  #data_$pos = apply(data_$avg[, 1:3], 2, function(X) acc2pos(data_$time, X))

  data_
}

acc2pos = function(t, a_t) {
  library(caTools)

  v_t = a_t * 0
  p_t = v_t

  for(i in 2:length(t)) {
    v_t[i] = trapz(t[1:i], a_t[1:i])
  }
  for(i in 3:length(t)) {
    p_t[i] = trapz(t[1:i], v_t[1:i])
  }
  p_t
  par(mfrow = c(3, 1))
  plot(t, a_t)
  plot(t, v_t)
  plot(t, p_t)
}

Movement = function(data_) {
  data_$top_threshold = quantile(data_$avg[, "norm"], .35)
  data_$bot_threshold = quantile(data_$avg[, "norm"], .65)

  data_$null = data_$avg[, "norm"] < data_$top_threshold
  data_$null = which(data_$null %in% TRUE)
  i = length(data_$null)
  while(i > 1) {
    if(abs(data_$null[i - 1] - data_$null[i]) < 15) {
      data_$null = data_$null[-i]
    }
    i = i - 1
  }

  i = 1
  while(i < length(data_$null) - 1) {
    if(max(data_$avg[data_$null[i]:data_$null[i + 1], "norm"]) < data_$bot_threshold)
      data_$null = data_$null[-i-1]
    else
      i = i + 1
  }

  data_
}

CountMovement = function(data_) {
  if(data_$exercice == 1) {
    count = length(data_$null)
  }
  return(count)
}

Score = function(data_) {
  theta = function(a, b) acos(sum(a*b) / (sqrt(sum(a * a)) * sqrt(sum(b * b))))
  resp = matrix(0, 1, length(data_$null))
  for(i in 1:(length(data_$null) - 1))
  {
    #print(paste("i", i))
    for(j in data_$null[i]:(data_$null[i + 1] - 1))
    {
      #print(data_$avg[j, 1:3])
      #print(theta(data_$avg[j, 1:3], data_$avg[j + 1, 1:3])/2/pi*360)
      if(theta(data_$avg[j, 1:3], data_$avg[j + 1, 1:3])/2/pi*360 > 7)
        resp[i] = resp[i] + 1
    }
    resp[i] = resp[i]/length(data_$null[i]:(data_$null[i + 1] - 1))
  }

  median(1 - resp)
}