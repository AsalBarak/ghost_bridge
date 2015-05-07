#
# atomic.py - Simple atoms for simple Eva demo
# Copyright (C) 2015  Linas Vepstas
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License v3 as
# published by the Free Software Foundation and including the exceptions
# at http://opencog.org/wiki/Licenses
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to:
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


from ros_commo import EventLoop
from opencog.atomspace import AtomSpace
from opencog.bindlink import satisfaction_link
from opencog.type_constructors import *

from opencog.cogserver import get_server_atomspace


# The atomspace where everything will live.
atomspace = get_server_atomspace()
set_type_ctor_atomspace(atomspace)

satisfaction_handle = SatisfactionLink(
	SequentialAndLink(
		EvaluationLink(
			GroundedPredicateNode("py: stop_go"),
			ListLink(
				ConceptNode("green light")
			)
		)
	)
}.h


result = satisfaction_link(atomspace, satisfaction_handle)
