from datetime import datetime
from flask import jsonify
import uuid
import psutil,os

class Info:
  ENV_MESSAGE = os.getenv('ENV_MESSAGE', default="Hello Python! This is Python Flask rest api!")

  def __init__(self):
    self.id         = uuid.uuid1()
    self.cpu        = psutil.cpu_percent(interval=0.9)
    self.mem        = psutil.virtual_memory().percent
    self.disk       = psutil.disk_usage("/").percent
    self.message    = Info.ENV_MESSAGE
    self.timestamp  = datetime.now()

  def get(self):
    return jsonify(
        requestid=self.id,
        cpu=self.cpu,
        mem=self.mem,
        disk=self.disk,
        msg=self.message,
        time=self.timestamp
    )